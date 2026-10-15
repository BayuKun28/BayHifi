package sync

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"bayhifi-server/auth"
	"bayhifi-server/database"
)

type PlaybackLogItem struct {
	ID               string `json:"id"`
	TrackID          string `json:"trackId"`
	Title            string `json:"title"`
	Artist           string `json:"artist"`
	Album            string `json:"album"`
	Genre            string `json:"genre"`
	DurationPlayedMs int    `json:"durationPlayedMs"`
	TrackDurationMs  int    `json:"trackDurationMs"`
	Format           string `json:"format"`
	SampleRate       int    `json:"sampleRate"`
	BitDepth         int    `json:"bitDepth"`
	Timestamp        string `json:"timestamp"`
	DriverName       string `json:"driverName,omitempty"`
	TargetName       string `json:"targetName,omitempty"`
	IsAutoEqActive   bool   `json:"isAutoEqActive"`
	ActiveDspCount   int    `json:"activeDspCount"`
	DacDeviceName    string `json:"dacDeviceName,omitempty"`
}

type SyncLogsRequest struct {
	Logs []PlaybackLogItem `json:"logs"`
}

type SyncLogsResponse struct {
	Success         bool   `json:"success"`
	SyncedCount     int    `json:"syncedCount"`
	TotalServerLogs int    `json:"totalServerLogs"`
	Message         string `json:"message,omitempty"`
}

type DspProfileData struct {
	ActivePresetName string          `json:"activePresetName"`
	DriverName       string          `json:"driverName"`
	TargetName       string          `json:"targetName"`
	IsAutoEqActive   bool            `json:"isAutoEqActive"`
	SafePreampDb     float64         `json:"safePreampDb"`
	Bands            json.RawMessage `json:"bands"`
	DspToggles       json.RawMessage `json:"dspToggles"`
	UpdatedAt        time.Time       `json:"updatedAt,omitempty"`
}

// SyncLogsHandler handles batch upsert and retrieval of playback logs from client
func SyncLogsHandler(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value(auth.UserIDContextKey).(string)

	if r.Method == http.MethodGet {
		limit := 500
		if lStr := r.URL.Query().Get("limit"); lStr != "" {
			if parsed, err := strconv.Atoi(lStr); err == nil && parsed > 0 && parsed <= 5000 {
				limit = parsed
			}
		}

		rows, err := database.DB.Query(`
			SELECT id, track_id, title, artist, album, genre,
			       duration_played_ms, track_duration_ms, format, sample_rate, bit_depth,
			       timestamp, driver_name, target_name, is_auto_eq_active, active_dsp_count, dac_device_name
			FROM playback_logs
			WHERE user_id = ?
			ORDER BY timestamp DESC
			LIMIT ?
		`, userID, limit)
		if err != nil {
			sendJSON(w, http.StatusInternalServerError, map[string]interface{}{"success": false, "message": err.Error()})
			return
		}
		defer rows.Close()

		logs := []PlaybackLogItem{}
		for rows.Next() {
			var l PlaybackLogItem
			var driver, target, dac sql.NullString
			var ts time.Time
			if err := rows.Scan(
				&l.ID, &l.TrackID, &l.Title, &l.Artist, &l.Album, &l.Genre,
				&l.DurationPlayedMs, &l.TrackDurationMs, &l.Format, &l.SampleRate, &l.BitDepth,
				&ts, &driver, &target, &l.IsAutoEqActive, &l.ActiveDspCount, &dac,
			); err == nil {
				l.Timestamp = ts.Format(time.RFC3339)
				if driver.Valid {
					l.DriverName = driver.String
				}
				if target.Valid {
					l.TargetName = target.String
				}
				if dac.Valid {
					l.DacDeviceName = dac.String
				}
				logs = append(logs, l)
			}
		}

		sendJSON(w, http.StatusOK, map[string]interface{}{
			"success": true,
			"logs":    logs,
			"count":   len(logs),
		})
		return
	}

	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req SyncLogsRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendJSON(w, http.StatusBadRequest, SyncLogsResponse{Success: false, Message: "Invalid JSON format"})
		return
	}

	tx, err := database.DB.Begin()
	if err != nil {
		sendJSON(w, http.StatusInternalServerError, SyncLogsResponse{Success: false, Message: "Transaction start failed"})
		return
	}
	defer tx.Rollback()

	stmt, err := tx.Prepare(`
		INSERT OR IGNORE INTO playback_logs (
			id, user_id, track_id, title, artist, album, genre,
			duration_played_ms, track_duration_ms, format, sample_rate, bit_depth,
			timestamp, driver_name, target_name, is_auto_eq_active, active_dsp_count, dac_device_name
		) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	`)
	if err != nil {
		sendJSON(w, http.StatusInternalServerError, SyncLogsResponse{Success: false, Message: "Prepare statement failed"})
		return
	}
	defer stmt.Close()

	synced := 0
	for _, l := range req.Logs {
		if l.ID == "" {
			continue
		}
		t, err := time.Parse(time.RFC3339, l.Timestamp)
		if err != nil {
			t = time.Now()
		}

		res, err := stmt.Exec(
			l.ID, userID, l.TrackID, l.Title, l.Artist, l.Album, l.Genre,
			l.DurationPlayedMs, l.TrackDurationMs, l.Format, l.SampleRate, l.BitDepth,
			t, l.DriverName, l.TargetName, l.IsAutoEqActive, l.ActiveDspCount, l.DacDeviceName,
		)
		if err == nil {
			if affected, _ := res.RowsAffected(); affected > 0 {
				synced++
			}
		}
	}

	if err := tx.Commit(); err != nil {
		sendJSON(w, http.StatusInternalServerError, SyncLogsResponse{Success: false, Message: "Transaction commit failed"})
		return
	}

	var totalLogs int
	_ = database.DB.QueryRow("SELECT COUNT(*) FROM playback_logs WHERE user_id = ?", userID).Scan(&totalLogs)

	sendJSON(w, http.StatusOK, SyncLogsResponse{
		Success:         true,
		SyncedCount:     synced,
		TotalServerLogs: totalLogs,
		Message:         fmt.Sprintf("Successfully processed %d logs (%d new saved)", len(req.Logs), synced),
	})
}

// GetDspProfileHandler fetches the user's active AutoEQ and DSP profile
func GetDspProfileHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID := r.Context().Value(auth.UserIDContextKey).(string)

	var p DspProfileData
	var bandsJSON, togglesJSON sql.NullString
	err := database.DB.QueryRow(`
		SELECT active_preset_name, driver_name, target_name, is_auto_eq_active, safe_preamp_db,
		       bands_json, dsp_toggles_json, updated_at
		FROM user_dsp_profiles
		WHERE user_id = ?
	`, userID).Scan(
		&p.ActivePresetName, &p.DriverName, &p.TargetName, &p.IsAutoEqActive, &p.SafePreampDb,
		&bandsJSON, &togglesJSON, &p.UpdatedAt,
	)

	if err == sql.ErrNoRows {
		sendJSON(w, http.StatusOK, map[string]interface{}{
			"success": true,
			"profile": nil,
		})
		return
	} else if err != nil {
		sendJSON(w, http.StatusInternalServerError, map[string]interface{}{"success": false, "message": err.Error()})
		return
	}

	if bandsJSON.Valid {
		p.Bands = json.RawMessage(bandsJSON.String)
	}
	if togglesJSON.Valid {
		p.DspToggles = json.RawMessage(togglesJSON.String)
	}

	sendJSON(w, http.StatusOK, map[string]interface{}{
		"success": true,
		"profile": p,
	})
}

// SaveDspProfileHandler saves or updates the user's active AutoEQ and DSP profile
func SaveDspProfileHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut && r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID := r.Context().Value(auth.UserIDContextKey).(string)

	var req DspProfileData
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendJSON(w, http.StatusBadRequest, map[string]interface{}{"success": false, "message": "Invalid JSON format"})
		return
	}

	bandsStr := string(req.Bands)
	togglesStr := string(req.DspToggles)
	now := time.Now()

	_, err := database.DB.Exec(`
		INSERT INTO user_dsp_profiles (
			user_id, active_preset_name, driver_name, target_name, is_auto_eq_active,
			safe_preamp_db, bands_json, dsp_toggles_json, updated_at
		) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(user_id) DO UPDATE SET
			active_preset_name = excluded.active_preset_name,
			driver_name = excluded.driver_name,
			target_name = excluded.target_name,
			is_auto_eq_active = excluded.is_auto_eq_active,
			safe_preamp_db = excluded.safe_preamp_db,
			bands_json = excluded.bands_json,
			dsp_toggles_json = excluded.dsp_toggles_json,
			updated_at = excluded.updated_at
	`, userID, req.ActivePresetName, req.DriverName, req.TargetName, req.IsAutoEqActive,
		req.SafePreampDb, bandsStr, togglesStr, now)

	if err != nil {
		sendJSON(w, http.StatusInternalServerError, map[string]interface{}{"success": false, "message": err.Error()})
		return
	}

	sendJSON(w, http.StatusOK, map[string]interface{}{
		"success": true,
		"message": "DSP and AutoEQ profile saved successfully",
	})
}

// GetWrappedSummaryHandler returns Studio Wrapped aggregate statistics for the user
func GetWrappedSummaryHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID := r.Context().Value(auth.UserIDContextKey).(string)
	yearParam := r.URL.Query().Get("year")
	year, err := strconv.Atoi(yearParam)
	if err != nil || year < 2000 {
		year = time.Now().Year()
	}

	startDate := fmt.Sprintf("%04d-01-01 00:00:00", year)
	endDate := fmt.Sprintf("%04d-12-31 23:59:59", year)

	// Total track plays & total listening time
	var totalPlays int
	var totalTimeMs int64
	_ = database.DB.QueryRow(`
		SELECT COUNT(*), COALESCE(SUM(duration_played_ms), 0)
		FROM playback_logs
		WHERE user_id = ? AND timestamp BETWEEN ? AND ?
	`, userID, startDate, endDate).Scan(&totalPlays, &totalTimeMs)

	// Top Artists
	type StatItem struct {
		Name  string `json:"name"`
		Count int    `json:"count"`
		Ms    int64  `json:"ms"`
	}
	topArtists := []StatItem{}
	rows, err := database.DB.Query(`
		SELECT artist, COUNT(*), SUM(duration_played_ms)
		FROM playback_logs
		WHERE user_id = ? AND timestamp BETWEEN ? AND ?
		GROUP BY artist
		ORDER BY SUM(duration_played_ms) DESC
		LIMIT 5
	`, userID, startDate, endDate)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var item StatItem
			if err := rows.Scan(&item.Name, &item.Count, &item.Ms); err == nil {
				topArtists = append(topArtists, item)
			}
		}
	}

	// Top Tracks
	topTracks := []StatItem{}
	rowsT, err := database.DB.Query(`
		SELECT title, COUNT(*), SUM(duration_played_ms)
		FROM playback_logs
		WHERE user_id = ? AND timestamp BETWEEN ? AND ?
		GROUP BY title
		ORDER BY SUM(duration_played_ms) DESC
		LIMIT 5
	`, userID, startDate, endDate)
	if err == nil {
		defer rowsT.Close()
		for rowsT.Next() {
			var item StatItem
			if err := rowsT.Scan(&item.Name, &item.Count, &item.Ms); err == nil {
				topTracks = append(topTracks, item)
			}
		}
	}

	sendJSON(w, http.StatusOK, map[string]interface{}{
		"success":     true,
		"year":        year,
		"totalPlays":  totalPlays,
		"totalTimeMs": totalTimeMs,
		"topArtists":  topArtists,
		"topTracks":   topTracks,
	})
}

// SyncSettingsHandler handles fetching and saving user preferences/settings
func SyncSettingsHandler(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value(auth.UserIDContextKey).(string)

	if r.Method == http.MethodGet {
		var settingsJSON sql.NullString
		var updatedAt time.Time
		err := database.DB.QueryRow(`
			SELECT settings_json, updated_at
			FROM user_settings
			WHERE user_id = ?
		`, userID).Scan(&settingsJSON, &updatedAt)

		if err == sql.ErrNoRows || !settingsJSON.Valid {
			sendJSON(w, http.StatusOK, map[string]interface{}{
				"success":  true,
				"settings": nil,
			})
			return
		} else if err != nil {
			sendJSON(w, http.StatusInternalServerError, map[string]interface{}{"success": false, "message": err.Error()})
			return
		}

		sendJSON(w, http.StatusOK, map[string]interface{}{
			"success":   true,
			"settings":  json.RawMessage(settingsJSON.String),
			"updatedAt": updatedAt.Format(time.RFC3339),
		})
		return
	}

	if r.Method == http.MethodPut || r.Method == http.MethodPost {
		var rawBody json.RawMessage
		if err := json.NewDecoder(r.Body).Decode(&rawBody); err != nil {
			sendJSON(w, http.StatusBadRequest, map[string]interface{}{"success": false, "message": "Invalid JSON format"})
			return
		}

		now := time.Now()
		_, err := database.DB.Exec(`
			INSERT INTO user_settings (user_id, settings_json, updated_at)
			VALUES (?, ?, ?)
			ON CONFLICT(user_id) DO UPDATE SET
				settings_json = excluded.settings_json,
				updated_at = excluded.updated_at
		`, userID, string(rawBody), now)

		if err != nil {
			sendJSON(w, http.StatusInternalServerError, map[string]interface{}{"success": false, "message": err.Error()})
			return
		}

		sendJSON(w, http.StatusOK, map[string]interface{}{
			"success":   true,
			"message":   "User settings saved successfully",
			"updatedAt": now.Format(time.RFC3339),
		})
		return
	}

	http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
}

func sendJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}
