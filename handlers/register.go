package handlers

import (
	"bytes"
	"crypto/rand"
	"encoding/json"
	"fmt"
	"go-rent/config"
	"go-rent/utils"
	"golang.org/x/crypto/bcrypt"
	"io"
	"math/big"
	"net/http"
	"regexp"
	"strings"
	"time"
)

type RegisterRequest struct {
	PhoneNumber string `json:"phone_number"`
	Name        string `json:"name"`
	Email       string `json:"email,omitempty"`
	NID         string `json:"nid,omitempty"`
	Password    string `json:"password"`
	Manager     *bool  `json:"manager,omitempty"`
}

type RegisterResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
	UserID  int64  `json:"user_id,omitempty"`
}

func generateRandomID() (int64, error) {
	// Generate a random number between 1000000 and 9999999
	max := big.NewInt(8999999)
	n, err := rand.Int(rand.Reader, max)
	if err != nil {
		return 0, err
	}
	// Add 1000000 to ensure 7-digit number
	return n.Int64() + 1000000, nil
}

func RegisterHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("\n=== New Registration Request ===")
	fmt.Printf("Method: %s\n", r.Method)
	fmt.Printf("URL: %s\n", r.URL)
	fmt.Printf("Headers: %v\n", r.Header)

	body, err := io.ReadAll(r.Body)
	if err != nil {
		fmt.Printf("Error reading request body: %v\n", err)
	}
	fmt.Printf("Request Body: %s\n", string(body))

	r.Body = io.NopCloser(bytes.NewBuffer(body)) // restore body for decoding

	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(RegisterResponse{false, "Method not allowed", 0})
		return
	}

	var req RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(RegisterResponse{false, "Invalid request body", 0})
		return
	}

	// Validate phone number
	phoneRegex := regexp.MustCompile(`^\+880 \d{4}-\d{6}$`)
	if !phoneRegex.MatchString(req.PhoneNumber) {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(RegisterResponse{false, "Invalid phone number format. Use format: +880 XXXX-XXXXXX", 0})
		return
	}

	// Normalize phone number
	phoneNumber := strings.ReplaceAll(req.PhoneNumber, " ", "")
	phoneNumber = strings.ReplaceAll(phoneNumber, "-", "")

	if req.Password == "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(RegisterResponse{false, "Password is required", 0})
		return
	}

	if req.Name == "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(RegisterResponse{false, "Name is required", 0})
		return
	}

	db, err := config.GetDBConnection()
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(RegisterResponse{false, "Database connection error", 0})
		return
	}
	defer db.Close()

	// Check if phone number exists
	var exists int
	err = db.QueryRow("SELECT COUNT(*) FROM user WHERE phone_number = ?", phoneNumber).Scan(&exists)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(RegisterResponse{false, "Database error", 0})
		return
	}
	if exists > 0 {
		w.WriteHeader(http.StatusConflict)
		json.NewEncoder(w).Encode(RegisterResponse{false, "Phone number already registered", 0})
		return
	}

	// Hash password
	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(RegisterResponse{false, "Error hashing password", 0})
		return
	}

	// Handle nullable fields
	var email interface{}
	if req.Email == "" {
		email = nil
	} else {
		// Validate email format
		emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
		if !emailRegex.MatchString(req.Email) {
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(RegisterResponse{false, "Invalid email format", 0})
			return
		}
		email = req.Email
	}

	var nid interface{}
	if req.NID == "" {
		nid = nil
	} else {
		// Validate NID format (assuming it should be numeric and 10-17 digits)
		nidRegex := regexp.MustCompile(`^\d{10,17}$`)
		if !nidRegex.MatchString(req.NID) {
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(RegisterResponse{false, "Invalid NID format. Should be 10-17 digits", 0})
			return
		}
		nid = req.NID
	}

	var manager interface{}
	if req.Manager == nil {
		manager = nil
	} else {
		manager = *req.Manager
	}

	// Generate random ID
	randomID, err := utils.GenerateRandomID()
	if err != nil {
		fmt.Printf("Error generating random ID: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(RegisterResponse{false, "Error generating user ID", 0})
		return
	}

	// Insert into DB with random ID
	result, err := db.Exec(
		`INSERT INTO user (id, name, phone_number, email, NID, password, manager, created_at, created_by, updated_at, updated_by)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		randomID,
		req.Name,
		phoneNumber,
		email,
		nid,
		string(hash),
		manager,
		time.Now().Format("2006-01-02"),
		randomID,
		time.Now().Format("2006-01-02"),
		randomID,
	)
	if err != nil {
		fmt.Printf("Error inserting user: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(RegisterResponse{false, fmt.Sprintf("Error inserting user: %v", err), 0})
		return
	}

	lastID, err := result.LastInsertId()
	if err != nil {
		fmt.Println("Inserted but failed to get last ID:", err)
	} else {
		fmt.Printf("User inserted with ID: %d\n", lastID)
	}

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(RegisterResponse{
		Success: true,
		Message: "Registration successful",
		UserID:  randomID,
	})
}
