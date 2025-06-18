package handlers

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"fmt"
	"go-rent/config"
	"go-rent/utils"
	"golang.org/x/crypto/bcrypt"
	"io"
	"net/http"
	"regexp"
	"strings"
	"time"
)

type LoginRequest struct {
	PhoneNumber string `json:"phone_number"`
	Password    string `json:"password"`
}

type LoginResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
	UserID  int64  `json:"user_id,omitempty"`
	Name    string `json:"name,omitempty"`
}

func LoginHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("\n=== New Login Request ===")
	fmt.Printf("Method: %s\n", r.Method)
	fmt.Printf("URL: %s\n", r.URL)

	// Read and log request body
	body, err := io.ReadAll(r.Body)
	if err != nil {
		fmt.Printf("Error reading request body: %v\n", err)
	}
	fmt.Printf("Request Body: %s\n", string(body))

	// Restore body for decoding
	r.Body = io.NopCloser(bytes.NewBuffer(body))

	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(LoginResponse{false, "Method not allowed", 0, ""})
		return
	}

	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(LoginResponse{false, "Invalid request body", 0, ""})
		return
	}

	// Validate phone number format
	phoneRegex := regexp.MustCompile(`^\+880 \d{4}-\d{6}$`)
	if !phoneRegex.MatchString(req.PhoneNumber) {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(LoginResponse{false, "Invalid phone number format. Use format: +880 XXXX-XXXXXX", 0, ""})
		return
	}

	// Normalize phone number
	phoneNumber := strings.ReplaceAll(req.PhoneNumber, " ", "")
	phoneNumber = strings.ReplaceAll(phoneNumber, "-", "")

	if req.Password == "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(LoginResponse{false, "Password is required", 0, ""})
		return
	}

	db, err := config.GetDBConnection()
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(LoginResponse{false, "Database connection error", 0, ""})
		return
	}
	defer db.Close()

	// Check if user exists and get their details
	var (
		userID   int64
		name     string
		password string
	)
	err = db.QueryRow("SELECT id, name, password FROM user WHERE phone_number = ?", phoneNumber).Scan(&userID, &name, &password)
	if err != nil {
		if err == sql.ErrNoRows {
			w.WriteHeader(http.StatusUnauthorized)
			json.NewEncoder(w).Encode(LoginResponse{false, "Invalid phone number or password", 0, ""})
			return
		}
		fmt.Printf("Database error: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(LoginResponse{false, "Database error", 0, ""})
		return
	}

	// Compare password
	err = bcrypt.CompareHashAndPassword([]byte(password), []byte(req.Password))
	if err != nil {
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(LoginResponse{false, "Invalid phone number or password", 0, ""})
		return
	}

	// Generate JWT token
	token, err := utils.GenerateToken(userID)
	if err != nil {
		fmt.Printf("Error generating token: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(LoginResponse{false, "Error generating authentication token", 0, ""})
		return
	}

	// Generate CSRF token
	csrfToken, err := utils.GenerateCSRFToken()
	if err != nil {
		fmt.Printf("Error generating CSRF token: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(LoginResponse{false, "Error generating CSRF token", 0, ""})
		return
	}

	fmt.Printf("Generated CSRF token: %s\n", csrfToken) // Debug log

	// Set session cookie with JWT token
	http.SetCookie(w, &http.Cookie{
		Name:     "sessiontoken",
		Value:    token,
		Expires:  time.Now().Add(24 * time.Hour),
		Path:     "/",
		HttpOnly: true,
		Secure:   false, // Set to true in production with HTTPS
		SameSite: http.SameSiteStrictMode,
	})

	// Set CSRF token cookie
	csrfCookie := &http.Cookie{
		Name:     "csrf_token",
		Value:    csrfToken,
		Expires:  time.Now().Add(24 * time.Hour),
		Path:     "/",
		Domain:   "localhost",
		HttpOnly: false, // Must be accessible via JavaScript
		Secure:   false, // Set to true in production with HTTPS
		SameSite: http.SameSiteLaxMode, // Changed from Strict to Lax for better compatibility
	}
	http.SetCookie(w, csrfCookie)

	fmt.Printf("Set CSRF cookie: %s\n", csrfCookie.String()) // Debug log

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(LoginResponse{
		Success: true,
		Message: "Login successful",
		UserID:  userID,
		Name:    name,
	})
} 