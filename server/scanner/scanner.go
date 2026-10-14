package scanner

import (
	"crypto/sha1"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"

	"bayhifi-server/database"

	"github.com/dhowden/tag"
)

var (
	isScanning bool
	scanMu     sync.Mutex
)

type TrackItem struct {
	ID                 string `json:"id"`
	FilePath           string `json:"filePath"`
	Title              string `json:"title"`
	Artist             string `json:"artist"`
	Album              string `json:"album"`
	AlbumArtist        string `json:"albumArtist,omitempty"`
	Genre              string `json:"genre,omitempty"`
	Year               int    `json:"year,omitempty"`
	TrackNumber        int    `json:"trackNumber,omitempty"`
	DurationMs         int    `json:"durationMs"`
	Format             string `json:"format"`
	Bitrate            int    `json:"bitrate,omitempty"`
	SampleRate         int    `json:"sampleRate,omitempty"`
	BitDepth           int    `json:"bitDepth,omitempty"`
	FileSizeBytes      int64  `json:"fileSizeBytes"`
	HasEmbeddedArtwork bool   `json:"hasEmbeddedArtwork"`
}

// SupportedExtensions defines playable audio formats
var SupportedExtensions = map[string]bool{
	".flac": true,
	".mp3":  true,
	".wav":  true,
	".m4a":  true,
	".aac":  true,
	".ogg":  true,
	".opus": true,
}

// ComputeTrackID generates a deterministic SHA1 hash of the file path
func ComputeTrackID(filePath string) string {
	h := sha1.New()
	h.Write([]byte(filePath))
	return hex.EncodeToString(h.Sum(nil))
}

// StartScan recursively indexes musicDir into SQLite library_tracks table
func StartScan(musicDir string) {
	scanMu.Lock()
	if isScanning {
		scanMu.Unlock()
		log.Println("[Scanner] Scan already in progress, skipping request")
		return
	}
	isScanning = true
	scanMu.Unlock()

	go func() {
		defer func() {
			scanMu.Lock()
			isScanning = false
			scanMu.Unlock()
		}()

		log.Printf("[Scanner] Starting directory scan of: %s", musicDir)
		startTime := time.Now()
		foundCount := 0
		indexedCount := 0

		stmt, err := database.DB.Prepare(`
			INSERT INTO library_tracks (
				id, file_path, title, artist, album, album_artist, genre,
				year, track_number, duration_ms, format, bitrate, sample_rate,
				bit_depth, file_size_bytes, has_embedded_artwork, updated_at
			) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
			ON CONFLICT(file_path) DO UPDATE SET
				title = excluded.title,
				artist = excluded.artist,
				album = excluded.album,
				album_artist = excluded.album_artist,
				genre = excluded.genre,
				year = excluded.year,
				track_number = excluded.track_number,
				duration_ms = excluded.duration_ms,
				format = excluded.format,
				file_size_bytes = excluded.file_size_bytes,
				has_embedded_artwork = excluded.has_embedded_artwork,
				updated_at = excluded.updated_at
		`)
		if err != nil {
			log.Printf("[Scanner] Failed to prepare insert statement: %v", err)
			return
		}
		defer stmt.Close()

		_ = filepath.Walk(musicDir, func(path string, info os.FileInfo, err error) error {
			if err != nil || info == nil || info.IsDir() {
				return nil
			}

			ext := strings.ToLower(filepath.Ext(path))
			if !SupportedExtensions[ext] {
				return nil
			}

			foundCount++
			trackID := ComputeTrackID(path)

			// Fallback defaults from file and folder name
			fileName := strings.TrimSuffix(filepath.Base(path), filepath.Ext(path))
			parentDir := filepath.Base(filepath.Dir(path))
			title := fileName
			artist := "Unknown Artist"
			album := parentDir
			genre := "Lossless Master"
			year := 0
			trackNum := 0
			hasArtwork := false

			// Try reading tags
			f, err := os.Open(path)
			if err == nil {
				metadata, err := tag.ReadFrom(f)
				if err == nil {
					if metadata.Title() != "" {
						title = metadata.Title()
					}
					if metadata.Artist() != "" {
						artist = metadata.Artist()
					}
					if metadata.Album() != "" {
						album = metadata.Album()
					}
					if metadata.Genre() != "" {
						genre = metadata.Genre()
					}
					year = metadata.Year()
					trackNum, _ = metadata.Track()
					hasArtwork = metadata.Picture() != nil
				}
				f.Close()
			}

			// Estimate duration from size if not parsed (rough fallback)
			durationMs := int((info.Size() / 44100 / 4) * 1000)
			if durationMs <= 0 {
				durationMs = 180000 // 3 min fallback
			}

			format := strings.TrimPrefix(ext, ".")
			now := time.Now()

			_, err = stmt.Exec(
				trackID, path, title, artist, album, artist, genre,
				year, trackNum, durationMs, format, 0, 44100, 16,
				info.Size(), hasArtwork, now,
			)
			if err == nil {
				indexedCount++
			}
			return nil
		})

		elapsed := time.Since(startTime)
		log.Printf("[Scanner] Scan completed in %v. Indexed %d/%d tracks.", elapsed, indexedCount, foundCount)
	}()
}

// GetTracksHandler returns list of indexed tracks in JSON format
func GetTracksHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	search := strings.TrimSpace(r.URL.Query().Get("search"))
	limitStr := r.URL.Query().Get("limit")
	offsetStr := r.URL.Query().Get("offset")

	limit := 200
	offset := 0
	if l, err := strconv.Atoi(limitStr); err == nil && l > 0 && l <= 50000 {
		limit = l
	}
	if o, err := strconv.Atoi(offsetStr); err == nil && o >= 0 {
		offset = o
	}

	var rows *sql.Rows
	var err error

	if search != "" {
		like := "%" + search + "%"
		rows, err = database.DB.Query(`
			SELECT id, file_path, title, artist, album, album_artist, genre,
			       year, track_number, duration_ms, format, bitrate, sample_rate,
			       bit_depth, file_size_bytes, has_embedded_artwork
			FROM library_tracks
			WHERE title LIKE ? OR artist LIKE ? OR album LIKE ?
			ORDER BY artist, album, track_number, title
			LIMIT ? OFFSET ?
		`, like, like, like, limit, offset)
	} else {
		rows, err = database.DB.Query(`
			SELECT id, file_path, title, artist, album, album_artist, genre,
			       year, track_number, duration_ms, format, bitrate, sample_rate,
			       bit_depth, file_size_bytes, has_embedded_artwork
			FROM library_tracks
			ORDER BY artist, album, track_number, title
			LIMIT ? OFFSET ?
		`, limit, offset)
	}

	if err != nil {
		http.Error(w, fmt.Sprintf("Query error: %v", err), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	tracks := []TrackItem{}
	for rows.Next() {
		var t TrackItem
		var albumArtist, genre sql.NullString
		err := rows.Scan(
			&t.ID, &t.FilePath, &t.Title, &t.Artist, &t.Album, &albumArtist, &genre,
			&t.Year, &t.TrackNumber, &t.DurationMs, &t.Format, &t.Bitrate, &t.SampleRate,
			&t.BitDepth, &t.FileSizeBytes, &t.HasEmbeddedArtwork,
		)
		if err == nil {
			if albumArtist.Valid {
				t.AlbumArtist = albumArtist.String
			}
			if genre.Valid {
				t.Genre = genre.String
			}
			tracks = append(tracks, t)
		}
	}

	var totalCount int
	_ = database.DB.QueryRow("SELECT COUNT(*) FROM library_tracks").Scan(&totalCount)

	scanMu.Lock()
	scanningStatus := isScanning
	scanMu.Unlock()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success":    true,
		"totalCount": totalCount,
		"limit":      limit,
		"offset":     offset,
		"isScanning": scanningStatus,
		"tracks":     tracks,
	})
}

// TriggerScanHandler triggers manual library re-scan
func TriggerScanHandler(musicDir string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		StartScan(musicDir)

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{
			"success": true,
			"message": "Library scanning started in background",
		})
	}
}

// StreamTrackHandler serves the audio file with HTTP 206 Range support
func StreamTrackHandler(w http.ResponseWriter, r *http.Request) {
	trackID := strings.TrimPrefix(r.URL.Path, "/api/library/stream/")
	if trackID == "" {
		http.Error(w, "Track ID required", http.StatusBadRequest)
		return
	}

	var filePath, format string
	err := database.DB.QueryRow(
		"SELECT file_path, format FROM library_tracks WHERE id = ?",
		trackID,
	).Scan(&filePath, &format)

	if err == sql.ErrNoRows {
		http.Error(w, "Track not found in database", http.StatusNotFound)
		return
	} else if err != nil {
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	file, err := os.Open(filePath)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to open audio file: %v", err), http.StatusNotFound)
		return
	}
	defer file.Close()

	info, err := file.Stat()
	if err != nil {
		http.Error(w, "Could not stat file", http.StatusInternalServerError)
		return
	}

	// Content-Type based on format
	switch strings.ToLower(format) {
	case "flac":
		w.Header().Set("Content-Type", "audio/flac")
	case "mp3":
		w.Header().Set("Content-Type", "audio/mpeg")
	case "wav":
		w.Header().Set("Content-Type", "audio/wav")
	case "ogg":
		w.Header().Set("Content-Type", "audio/ogg")
	case "opus":
		w.Header().Set("Content-Type", "audio/opus")
	case "m4a", "aac":
		w.Header().Set("Content-Type", "audio/mp4")
	default:
		w.Header().Set("Content-Type", "application/octet-stream")
	}

	w.Header().Set("Accept-Ranges", "bytes")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	// http.ServeContent handles HTTP 206 Partial Content automatically!
	http.ServeContent(w, r, filepath.Base(filePath), info.ModTime(), file)
}

// CoverArtHandler serves embedded artwork or directory cover.jpg
func CoverArtHandler(w http.ResponseWriter, r *http.Request) {
	trackID := strings.TrimPrefix(r.URL.Path, "/api/library/cover/")
	if trackID == "" {
		http.Error(w, "Track ID required", http.StatusBadRequest)
		return
	}

	var filePath string
	err := database.DB.QueryRow(
		"SELECT file_path FROM library_tracks WHERE id = ?",
		trackID,
	).Scan(&filePath)

	if err != nil {
		http.Error(w, "Track not found", http.StatusNotFound)
		return
	}

	// 1. Try reading embedded artwork
	f, err := os.Open(filePath)
	if err == nil {
		metadata, err := tag.ReadFrom(f)
		if err == nil && metadata.Picture() != nil {
			pic := metadata.Picture()
			w.Header().Set("Content-Type", pic.MIMEType)
			w.Header().Set("Cache-Control", "public, max-age=604800") // 7 days
			w.Header().Set("Access-Control-Allow-Origin", "*")
			_, _ = w.Write(pic.Data)
			f.Close()
			return
		}
		f.Close()
	}

	// 2. Fallback: check for cover.jpg, folder.jpg in the same directory
	dir := filepath.Dir(filePath)
	candidates := []string{"cover.jpg", "folder.jpg", "cover.png", "folder.png", "front.jpg"}
	for _, c := range candidates {
		coverPath := filepath.Join(dir, c)
		if info, err := os.Stat(coverPath); err == nil && !info.IsDir() {
			cFile, err := os.Open(coverPath)
			if err == nil {
				defer cFile.Close()
				w.Header().Set("Cache-Control", "public, max-age=604800")
				w.Header().Set("Access-Control-Allow-Origin", "*")
				if strings.HasSuffix(c, ".png") {
					w.Header().Set("Content-Type", "image/png")
				} else {
					w.Header().Set("Content-Type", "image/jpeg")
				}
				_, _ = io.Copy(w, cFile)
				return
			}
		}
	}

	http.Error(w, "No artwork found", http.StatusNotFound)
}
