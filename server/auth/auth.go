package auth

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"bayhifi-server/database"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

type contextKey string

const UserIDContextKey contextKey = "userId"

var JwtSecret = []byte("bayhifi_default_secure_secret_2026")

type User struct {
	ID        string    `json:"id"`
	Username  string    `json:"username"`
	Email     string    `json:"email,omitempty"`
	CreatedAt time.Time `json:"createdAt"`
}

type RegisterRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
	Email    string `json:"email,omitempty"`
}

type LoginRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type AuthResponse struct {
	Success bool   `json:"success"`
	Token   string `json:"token,omitempty"`
	User    *User  `json:"user,omitempty"`
	Message string `json:"message,omitempty"`
}

type Claims struct {
	UserID   string `json:"userId"`
	Username string `json:"username"`
	jwt.RegisteredClaims
}

// GenerateToken creates a signed JWT token valid for 30 days
func GenerateToken(user *User) (string, error) {
	expirationTime := time.Now().Add(30 * 24 * time.Hour)
	claims := &Claims{
		UserID:   user.ID,
		Username: user.Username,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expirationTime),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Issuer:    "bayhifi-server",
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(JwtSecret)
}

// RegisterHandler handles user registration
func RegisterHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendJSON(w, http.StatusBadRequest, AuthResponse{Success: false, Message: "Invalid JSON request body"})
		return
	}

	req.Username = strings.TrimSpace(req.Username)
	req.Password = strings.TrimSpace(req.Password)
	if len(req.Username) < 3 {
		sendJSON(w, http.StatusBadRequest, AuthResponse{Success: false, Message: "Username must be at least 3 characters"})
		return
	}
	if len(req.Password) < 4 {
		sendJSON(w, http.StatusBadRequest, AuthResponse{Success: false, Message: "Password must be at least 4 characters"})
		return
	}

	// Check if username already exists
	var count int
	err := database.DB.QueryRow("SELECT COUNT(*) FROM users WHERE username = ?", req.Username).Scan(&count)
	if err != nil {
		sendJSON(w, http.StatusInternalServerError, AuthResponse{Success: false, Message: "Database query failed"})
		return
	}
	if count > 0 {
		sendJSON(w, http.StatusConflict, AuthResponse{Success: false, Message: "Username is already registered"})
		return
	}

	// Hash password
	hashed, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		sendJSON(w, http.StatusInternalServerError, AuthResponse{Success: false, Message: "Password hashing failed"})
		return
	}

	// Insert new user
	userID := fmt.Sprintf("usr_%d", time.Now().UnixNano())
	now := time.Now()
	_, err = database.DB.Exec(
		"INSERT INTO users (id, username, email, password_hash, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
		userID, req.Username, req.Email, string(hashed), now, now,
	)
	if err != nil {
		sendJSON(w, http.StatusInternalServerError, AuthResponse{Success: false, Message: fmt.Sprintf("Failed to create user: %v", err)})
		return
	}

	user := &User{
		ID:        userID,
		Username:  req.Username,
		Email:     req.Email,
		CreatedAt: now,
	}

	token, err := GenerateToken(user)
	if err != nil {
		sendJSON(w, http.StatusInternalServerError, AuthResponse{Success: false, Message: "Failed to generate session token"})
		return
	}

	sendJSON(w, http.StatusCreated, AuthResponse{
		Success: true,
		Token:   token,
		User:    user,
		Message: "Registration successful",
	})
}

// LoginHandler handles user login
func LoginHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendJSON(w, http.StatusBadRequest, AuthResponse{Success: false, Message: "Invalid JSON request body"})
		return
	}

	req.Username = strings.TrimSpace(req.Username)
	req.Password = strings.TrimSpace(req.Password)

	var user User
	var passwordHash string
	var email sql.NullString
	err := database.DB.QueryRow(
		"SELECT id, username, email, password_hash, created_at FROM users WHERE username = ?",
		req.Username,
	).Scan(&user.ID, &user.Username, &email, &passwordHash, &user.CreatedAt)

	if err == sql.ErrNoRows {
		sendJSON(w, http.StatusUnauthorized, AuthResponse{Success: false, Message: "Invalid username or password"})
		return
	} else if err != nil {
		sendJSON(w, http.StatusInternalServerError, AuthResponse{Success: false, Message: "Database query failed"})
		return
	}

	if email.Valid {
		user.Email = email.String
	}

	// Verify password
	if err := bcrypt.CompareHashAndPassword([]byte(passwordHash), []byte(req.Password)); err != nil {
		sendJSON(w, http.StatusUnauthorized, AuthResponse{Success: false, Message: "Invalid username or password"})
		return
	}

	token, err := GenerateToken(&user)
	if err != nil {
		sendJSON(w, http.StatusInternalServerError, AuthResponse{Success: false, Message: "Failed to generate session token"})
		return
	}

	sendJSON(w, http.StatusOK, AuthResponse{
		Success: true,
		Token:   token,
		User:    &user,
		Message: "Login successful",
	})
}

// MeHandler returns the authenticated user's details
func MeHandler(w http.ResponseWriter, r *http.Request) {
	userID, ok := r.Context().Value(UserIDContextKey).(string)
	if !ok || userID == "" {
		sendJSON(w, http.StatusUnauthorized, AuthResponse{Success: false, Message: "Unauthorized"})
		return
	}

	var user User
	var email sql.NullString
	err := database.DB.QueryRow(
		"SELECT id, username, email, created_at FROM users WHERE id = ?",
		userID,
	).Scan(&user.ID, &user.Username, &email, &user.CreatedAt)

	if err != nil {
		sendJSON(w, http.StatusNotFound, AuthResponse{Success: false, Message: "User not found"})
		return
	}
	if email.Valid {
		user.Email = email.String
	}

	sendJSON(w, http.StatusOK, AuthResponse{
		Success: true,
		User:    &user,
	})
}

type ChangePasswordRequest struct {
	OldPassword string `json:"oldPassword"`
	NewPassword string `json:"newPassword"`
}

// ChangePasswordHandler allows an authenticated user to update their password
func ChangePasswordHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	userID, ok := r.Context().Value(UserIDContextKey).(string)
	if !ok || userID == "" {
		sendJSON(w, http.StatusUnauthorized, AuthResponse{Success: false, Message: "Unauthorized"})
		return
	}

	var req ChangePasswordRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendJSON(w, http.StatusBadRequest, AuthResponse{Success: false, Message: "Invalid JSON request body"})
		return
	}

	req.OldPassword = strings.TrimSpace(req.OldPassword)
	req.NewPassword = strings.TrimSpace(req.NewPassword)
	if req.OldPassword == "" {
		sendJSON(w, http.StatusBadRequest, AuthResponse{Success: false, Message: "Current password is required"})
		return
	}
	if len(req.NewPassword) < 4 {
		sendJSON(w, http.StatusBadRequest, AuthResponse{Success: false, Message: "New password must be at least 4 characters"})
		return
	}

	var currentHash string
	err := database.DB.QueryRow("SELECT password_hash FROM users WHERE id = ?", userID).Scan(&currentHash)
	if err == sql.ErrNoRows {
		sendJSON(w, http.StatusNotFound, AuthResponse{Success: false, Message: "User not found"})
		return
	} else if err != nil {
		sendJSON(w, http.StatusInternalServerError, AuthResponse{Success: false, Message: "Database query failed"})
		return
	}

	// Verify old password
	if err := bcrypt.CompareHashAndPassword([]byte(currentHash), []byte(req.OldPassword)); err != nil {
		sendJSON(w, http.StatusUnauthorized, AuthResponse{Success: false, Message: "Current password is incorrect"})
		return
	}

	// Hash new password
	newHash, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		sendJSON(w, http.StatusInternalServerError, AuthResponse{Success: false, Message: "Password hashing failed"})
		return
	}

	// Update user record
	_, err = database.DB.Exec("UPDATE users SET password_hash = ?, updated_at = ? WHERE id = ?", string(newHash), time.Now(), userID)
	if err != nil {
		sendJSON(w, http.StatusInternalServerError, AuthResponse{Success: false, Message: "Failed to update password in database"})
		return
	}

	sendJSON(w, http.StatusOK, AuthResponse{
		Success: true,
		Message: "Password updated successfully",
	})
}

// AuthMiddleware protects routes requiring user authentication
func AuthMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
			sendJSON(w, http.StatusUnauthorized, AuthResponse{Success: false, Message: "Missing or invalid Authorization header"})
			return
		}

		tokenStr := strings.TrimPrefix(authHeader, "Bearer ")
		claims := &Claims{}
		token, err := jwt.ParseWithClaims(tokenStr, claims, func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
			}
			return JwtSecret, nil
		})

		if err != nil || !token.Valid {
			sendJSON(w, http.StatusUnauthorized, AuthResponse{Success: false, Message: "Invalid or expired session token"})
			return
		}

		ctx := context.WithValue(r.Context(), UserIDContextKey, claims.UserID)
		next(w, r.WithContext(ctx))
	}
}

func sendJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}
