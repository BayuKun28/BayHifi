package database

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"path/filepath"

	_ "modernc.org/sqlite"
)

var DB *sql.DB

// InitDB initializes SQLite database with WAL mode and runs necessary migrations
func InitDB(dbPath string) (*sql.DB, error) {
	// Ensure parent directory exists
	dir := filepath.Dir(dbPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create db directory %s: %w", dir, err)
	}

	// Open SQLite database
	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return nil, fmt.Errorf("failed to open sqlite database: %w", err)
	}

	// SQLite Performance & Concurrency PRAGMAs
	pragmas := []string{
		"PRAGMA journal_mode = WAL;",
		"PRAGMA busy_timeout = 5000;",
		"PRAGMA synchronous = NORMAL;",
		"PRAGMA cache_size = -64000;", // 64MB cache
		"PRAGMA foreign_keys = ON;",
	}

	for _, p := range pragmas {
		if _, err := db.Exec(p); err != nil {
			log.Printf("[DB] Warning: PRAGMA exec failed (%s): %v", p, err)
		}
	}

	// Run Schema Migrations
	migration := `
	CREATE TABLE IF NOT EXISTS users (
		id TEXT PRIMARY KEY,
		username TEXT UNIQUE NOT NULL,
		email TEXT UNIQUE,
		password_hash TEXT NOT NULL,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);

	CREATE TABLE IF NOT EXISTS user_dsp_profiles (
		user_id TEXT PRIMARY KEY,
		active_preset_name TEXT,
		driver_name TEXT,
		target_name TEXT,
		is_auto_eq_active BOOLEAN DEFAULT 0,
		safe_preamp_db REAL DEFAULT 0.0,
		bands_json TEXT,
		dsp_toggles_json TEXT,
		updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
	);

	CREATE TABLE IF NOT EXISTS user_settings (
		user_id TEXT PRIMARY KEY,
		settings_json TEXT NOT NULL,
		updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
	);

	CREATE TABLE IF NOT EXISTS playback_logs (
		id TEXT PRIMARY KEY,
		user_id TEXT NOT NULL,
		track_id TEXT NOT NULL,
		title TEXT NOT NULL,
		artist TEXT NOT NULL,
		album TEXT NOT NULL,
		genre TEXT NOT NULL,
		duration_played_ms INTEGER NOT NULL,
		track_duration_ms INTEGER NOT NULL,
		format TEXT NOT NULL,
		sample_rate INTEGER NOT NULL,
		bit_depth INTEGER NOT NULL,
		timestamp DATETIME NOT NULL,
		driver_name TEXT,
		target_name TEXT,
		is_auto_eq_active BOOLEAN DEFAULT 0,
		active_dsp_count INTEGER DEFAULT 0,
		dac_device_name TEXT,
		synced_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
	);
	CREATE INDEX IF NOT EXISTS idx_logs_user_timestamp ON playback_logs(user_id, timestamp);

	CREATE TABLE IF NOT EXISTS library_tracks (
		id TEXT PRIMARY KEY,
		file_path TEXT UNIQUE NOT NULL,
		title TEXT NOT NULL,
		artist TEXT NOT NULL,
		album TEXT NOT NULL,
		album_artist TEXT,
		genre TEXT,
		year INTEGER,
		track_number INTEGER,
		duration_ms INTEGER NOT NULL,
		format TEXT NOT NULL,
		bitrate INTEGER,
		sample_rate INTEGER,
		bit_depth INTEGER,
		file_size_bytes INTEGER NOT NULL,
		has_embedded_artwork BOOLEAN DEFAULT 0,
		updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);
	CREATE INDEX IF NOT EXISTS idx_tracks_artist ON library_tracks(artist);
	CREATE INDEX IF NOT EXISTS idx_tracks_album ON library_tracks(album);
	`

	if _, err := db.Exec(migration); err != nil {
		return nil, fmt.Errorf("failed to run database migrations: %w", err)
	}

	DB = db
	log.Printf("[DB] SQLite database successfully initialized at: %s (WAL mode enabled)", dbPath)
	return db, nil
}
