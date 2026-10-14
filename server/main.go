package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	"bayhifi-server/auth"
	"bayhifi-server/database"
	"bayhifi-server/proxy"
	"bayhifi-server/scanner"
	"bayhifi-server/sync"
)

func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		reqHeaders := r.Header.Get("Access-Control-Request-Headers")
		if reqHeaders != "" {
			w.Header().Set("Access-Control-Allow-Headers", reqHeaders)
		} else {
			w.Header().Set("Access-Control-Allow-Headers", "*")
		}

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8081"
	}

	musicDir := os.Getenv("MUSIC_DIR")
	if musicDir == "" {
		musicDir = "/music"
	}

	dbPath := os.Getenv("DB_PATH")
	if dbPath == "" {
		dbPath = "./bayhifi.db"
	}

	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret != "" {
		auth.JwtSecret = []byte(jwtSecret)
	}

	log.Printf("[BayHifi Server] Starting with Port=%s, MusicDir=%s, DBPath=%s", port, musicDir, dbPath)

	// Initialize Database
	db, err := database.InitDB(dbPath)
	if err != nil {
		log.Fatalf("[BayHifi Server] Database initialization failed: %v", err)
	}
	defer db.Close()

	// Initial directory scan if directory exists
	if info, err := os.Stat(musicDir); err == nil && info.IsDir() {
		log.Printf("[BayHifi Server] Music directory found at %s. Triggering scan...", musicDir)
		scanner.StartScan(musicDir)
	} else {
		log.Printf("[BayHifi Server] Warning: Music directory %s not found or not accessible yet.", musicDir)
	}

	mux := http.NewServeMux()

	// Health Check
	mux.HandleFunc("/api/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  "ok",
			"service": "bayhifi-server",
			"version": "1.0.0",
		})
	})

	// Auth Endpoints
	mux.HandleFunc("/api/auth/register", auth.RegisterHandler)
	mux.HandleFunc("/api/auth/login", auth.LoginHandler)
	mux.HandleFunc("/api/auth/me", auth.AuthMiddleware(auth.MeHandler))
	mux.HandleFunc("/api/auth/change-password", auth.AuthMiddleware(auth.ChangePasswordHandler))

	// Cloud Sync Endpoints (Offline-first sync)
	mux.HandleFunc("/api/sync/logs", auth.AuthMiddleware(sync.SyncLogsHandler))
	mux.HandleFunc("/api/sync/dsp", func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodGet {
			auth.AuthMiddleware(sync.GetDspProfileHandler)(w, r)
		} else if r.Method == http.MethodPut || r.Method == http.MethodPost {
			auth.AuthMiddleware(sync.SaveDspProfileHandler)(w, r)
		} else {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})
	mux.HandleFunc("/api/analytics/wrapped", auth.AuthMiddleware(sync.GetWrappedSummaryHandler))

	// Library Endpoints (Directory Scanner & Streaming)
	mux.HandleFunc("/api/library/tracks", scanner.GetTracksHandler)
	mux.HandleFunc("/api/library/scan", scanner.TriggerScanHandler(musicDir))
	mux.HandleFunc("/api/library/stream/", scanner.StreamTrackHandler)
	mux.HandleFunc("/api/library/cover/", scanner.CoverArtHandler)

	// Generic CORS and Streaming Proxy (For YouTube Music on Web)
	mux.HandleFunc("/api/proxy", proxy.ProxyHandler)

	handler := corsMiddleware(mux)

	addr := fmt.Sprintf(":%s", port)
	log.Printf("[BayHifi Server] Listening on http://0.0.0.0%s", addr)
	if err := http.ListenAndServe(addr, handler); err != nil {
		log.Fatalf("[BayHifi Server] Server exited: %v", err)
	}
}
