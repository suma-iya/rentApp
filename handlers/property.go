package handlers

import (
	
	"database/sql"
	"encoding/json"
	"fmt"
	"go-rent/config"
	"go-rent/utils"
	
	"net/http"
	"strconv"
	"strings"
	"time"
	"github.com/gorilla/mux"
)

type PropertyRequest struct {
	Name    string `json:"name"`
	Address string `json:"address"`
}

type PropertyResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
	PropertyID int64 `json:"property_id,omitempty"`
}

type Property struct {
	ID        int64  `json:"id"`
	Name      string `json:"name"`
	Address   string `json:"address"`
	CreatedAt string `json:"created_at"`
}

type UserPropertiesResponse struct {
	Success   bool       `json:"success"`
	Message   string     `json:"message"`
	Properties []Property `json:"properties"`
}

type SinglePropertyResponse struct {
	Success bool     `json:"success"`
	Message string   `json:"message"`
	Property Property `json:"property,omitempty"`
	Floors   []Floor  `json:"floors,omitempty"`
	IsManager bool    `json:"is_manager,omitempty"`
}

type Floor struct {
	ID        int64  `json:"id"`
	Name      string `json:"name"`
	Rent      int    `json:"rent"`
	CreatedAt string `json:"created_at"`
	Tenant    *int64 `json:"tenant,omitempty"`
	Status    string `json:"status,omitempty"`
	NotificationID *int64 `json:"notification_id,omitempty"`
}

type FloorRequest struct {
	Name              string `json:"name"`
	Rent             int    `json:"rent"`
	Tenant           *int64 `json:"tenant,omitempty"`
	DueRent          int    `json:"due_rent,omitempty"`
	DueElectricityBill int  `json:"due_electricity_bill,omitempty"`
	ReceivedMoney    int    `json:"received_money,omitempty"`
}

type FloorResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
	FloorID int64  `json:"floor_id,omitempty"`
}

type UserPhone struct {
	ID    int64  `json:"id"`
	Phone string `json:"phone_number"`
}

type UserPhonesResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message"`
	Users   []UserPhone `json:"users"`
}

type UserIDResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
	UserID  int64  `json:"user_id,omitempty"`
}

type PaymentRequest struct {
	DueRent          int  `json:"due_rent"`
	DueElectricityBill int  `json:"due_electricity_bill"`
	ReceivedMoney    int  `json:"received_money"`
	FullPayment      bool `json:"full_payment"`
}

type PaymentResponse struct {
	Success   bool   `json:"success"`
	Message   string `json:"message"`
	PaymentID int64  `json:"payment_id,omitempty"`
}

type TenantRequestResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
}

type Notification struct {
	ID        int64  `json:"id"`
	Message   string `json:"message"`
	Status    string `json:"status"`
	CreatedAt string `json:"created_at"`
	Property  struct {
		ID   int64  `json:"id"`
		Name string `json:"name"`
	} `json:"property"`
	Floor struct {
		ID   int64  `json:"id"`
		Name string `json:"name"`
	} `json:"floor"`
	ShowActions bool `json:"show_actions"`
}

type NotificationsResponse struct {
	Success       bool          `json:"success"`
	Message       string        `json:"message"`
	Notifications []Notification `json:"notifications"`
}

func AddPropertyHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("\n=== New Add Property Request ===")
	fmt.Printf("Method: %s\n", r.Method)
	fmt.Printf("URL: %s\n", r.URL)

	// Set response header to JSON
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(PropertyResponse{false, "Method not allowed", 0})
		return
	}

	// Get user ID from session
	userID := getUserIDFromSession(r)
	if userID == 0 {
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(PropertyResponse{false, "User not authenticated", 0})
		return
	}

	var req PropertyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(PropertyResponse{false, "Invalid request body", 0})
		return
	}

	if req.Name == "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(PropertyResponse{false, "Property name is required", 0})
		return
	}

	db, err := config.GetDBConnection()
	if err != nil {
		fmt.Printf("Database connection error: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(PropertyResponse{false, "Database connection error", 0})
		return
	}

	// Generate random ID for property
	randomID, err := utils.GenerateRandomID()
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(PropertyResponse{false, "Error generating property ID", 0})
		return
	}

	// Insert property into database
	_, err = db.Exec(
		`INSERT INTO property (id, name, address, created_at, created_by, updated_at, updated_by)
		VALUES (?, ?, ?, ?, ?, ?, ?)`,
		randomID,
		req.Name,
		req.Address,
		time.Now().In(time.FixedZone("BDT", 6*60*60)).Format("2006-01-02 15:04:05"),
		userID,
		time.Now().In(time.FixedZone("BDT", 6*60*60)).Format("2006-01-02 15:04:05"),
		userID,
	)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(PropertyResponse{false, "Error adding property", 0})
		return
	}

	// Insert into takes_care_of table
	takesCareID, err := utils.GenerateRandomID()
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(PropertyResponse{false, "Error generating care ID", 0})
		return
	}

	_, err = db.Exec(
		`INSERT INTO takes_care_of (id, uid, pid, created_at, created_by, updated_at, updated_by)
		VALUES (?, ?, ?, ?, ?, ?, ?)`,
		takesCareID,
		userID,
		randomID,
		time.Now().In(time.FixedZone("BDT", 6*60*60)).Format("2006-01-02 15:04:05"),
		userID,
		time.Now().In(time.FixedZone("BDT", 6*60*60)).Format("2006-01-02 15:04:05"),
		userID,
	)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(PropertyResponse{false, "Error saving property care details", 0})
		return
	}

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(PropertyResponse{
		Success: true,
		Message: "Property added successfully",
		PropertyID: randomID,
	})
}

// getUserIDFromSession retrieves the user ID from the session token
func getUserIDFromSession(r *http.Request) int64 {
	// Get token from cookie
	cookie, err := r.Cookie("sessiontoken")
	if err != nil {
		fmt.Printf("Error getting session token: %v\n", err)
		return 0 // Return 0 to indicate no user ID found
	}

	// Validate token and get user ID
	userID, err := utils.ValidateToken(cookie.Value)
	if err != nil {
		fmt.Printf("Error validating token: %v\n", err)
		return 0 // Return 0 to indicate no user ID found
	}

	return userID
}

func GetUserPropertiesHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("\n=== New Get User Properties Request ===")
	fmt.Printf("Method: %s\n", r.Method)
	fmt.Printf("URL: %s\n", r.URL)

	// Set response header to JSON
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodGet {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(UserPropertiesResponse{false, "Method not allowed", nil})
		return
	}

	// Get user ID from session
	userID := getUserIDFromSession(r)
	if userID == 0 {
		fmt.Println("No user ID found in session")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(UserPropertiesResponse{false, "User not authenticated", nil})
		return
	}

	fmt.Printf("Fetching properties for user ID: %d\n", userID)

	db, err := config.GetDBConnection()
	if err != nil {
		fmt.Printf("Database connection error: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(UserPropertiesResponse{false, "Database connection error", nil})
		return
	}

	// Query to get all properties for the user
	query := `
		SELECT p.id, p.name, p.address, p.created_at 
		FROM property p
		INNER JOIN takes_care_of t ON p.id = t.pid
		WHERE t.uid = ?
		ORDER BY p.created_at DESC`
	
	fmt.Printf("Executing query: %s with userID: %d\n", query, userID)
	
	rows, err := db.Query(query, userID)
	if err != nil {
		fmt.Printf("Error querying properties: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(UserPropertiesResponse{false, "Error fetching properties", nil})
		return
	}
	defer rows.Close()

	var properties []Property
	for rows.Next() {
		var prop Property
		if err := rows.Scan(&prop.ID, &prop.Name, &prop.Address, &prop.CreatedAt); err != nil {
			fmt.Printf("Error scanning property row: %v\n", err)
			continue
		}
		properties = append(properties, prop)
		fmt.Printf("Found property: ID=%d, Name=%s\n", prop.ID, prop.Name)
	}

	if err = rows.Err(); err != nil {
		fmt.Printf("Error iterating property rows: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(UserPropertiesResponse{false, "Error processing properties", nil})
		return
	}

	fmt.Printf("Found %d properties\n", len(properties))

	response := UserPropertiesResponse{
		Success: true,
		Message: "Properties retrieved successfully",
		Properties: properties,
	}

	// Log the response
	responseJSON, _ := json.MarshalIndent(response, "", "  ")
	fmt.Printf("Sending response: %s\n", string(responseJSON))

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

func GetPropertyByIDHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("\n=== New Get Property By ID Request ===")
	fmt.Printf("Method: %s\n", r.Method)
	fmt.Printf("URL: %s\n", r.URL)

	// Set response header to JSON
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodGet {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(SinglePropertyResponse{false, "Method not allowed", Property{}, nil, false})
		return
	}

	// Get user ID from session
	userID := getUserIDFromSession(r)
	if userID == 0 {
		fmt.Println("No user ID found in session")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(SinglePropertyResponse{false, "User not authenticated", Property{}, nil, false})
		return
	}

	// Extract property ID from URL
	pathParts := strings.Split(r.URL.Path, "/")
	if len(pathParts) != 3 {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(SinglePropertyResponse{false, "Invalid property ID format", Property{}, nil, false})
		return
	}

	propertyID, err := strconv.ParseInt(pathParts[2], 10, 64)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(SinglePropertyResponse{false, "Invalid property ID", Property{}, nil, false})
		return
	}

	fmt.Printf("Fetching property ID: %d for user ID: %d\n", propertyID, userID)

	db, err := config.GetDBConnection()
	if err != nil {
		fmt.Printf("Database connection error: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(SinglePropertyResponse{false, "Database connection error", Property{}, nil, false})
		return
	}

	// Query to get the specific property and verify user has access
	query := `
		SELECT p.id, p.name, p.address, p.created_at 
		FROM property p
		WHERE p.id = ? AND (
			EXISTS (
				SELECT 1 FROM takes_care_of t 
				WHERE t.pid = p.id AND t.uid = ?
			) OR EXISTS (
				SELECT 1 FROM floor f 
				WHERE f.pid = p.id AND f.tenant = ?
			)
		)`
	
	fmt.Printf("Executing query: %s with propertyID: %d, userID: %d\n", query, propertyID, userID, userID)
	
	var prop Property
	err = db.QueryRow(query, propertyID, userID, userID).Scan(&prop.ID, &prop.Name, &prop.Address, &prop.CreatedAt)
	if err != nil {
		fmt.Printf("Error querying property: %v\n", err)
		w.WriteHeader(http.StatusNotFound)
		json.NewEncoder(w).Encode(SinglePropertyResponse{false, "Property not found or access denied", Property{}, nil, false})
		return
	}

	// Get all floors for this property
	floorsQuery := `
		SELECT f.id, f.name, f.rent, f.created_at, f.tenant,
		       EXISTS(
		           SELECT 1 FROM notification n 
		           WHERE n.fid = f.id AND n.status = 'pending'
		       ) as has_pending_request,
		       (
		           SELECT n.id 
		           FROM notification n 
		           WHERE n.fid = f.id AND n.status = 'pending'
		           LIMIT 1
		       ) as notification_id
		FROM floor f
		WHERE f.pid = ?
		ORDER BY f.created_at DESC`
	
	rows, err := db.Query(floorsQuery, propertyID)
	if err != nil {
		fmt.Printf("Error querying floors: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(SinglePropertyResponse{false, "Error fetching floors", prop, nil, false})
		return
	}
	defer rows.Close()

	var floors []Floor
	for rows.Next() {
		var floor Floor
		var tenant sql.NullInt64
		var hasPendingRequest bool
		var notificationID sql.NullInt64
		if err := rows.Scan(&floor.ID, &floor.Name, &floor.Rent, &floor.CreatedAt, &tenant, &hasPendingRequest, &notificationID); err != nil {
			fmt.Printf("Error scanning floor row: %v\n", err)
			continue
		}
		if tenant.Valid {
			floor.Tenant = &tenant.Int64
		}
		if hasPendingRequest {
			floor.Status = "pending"
			if notificationID.Valid {
				floor.NotificationID = &notificationID.Int64
			}
		}
		floors = append(floors, floor)
	}

	fmt.Printf("Found property: ID=%d, Name=%s with %d floors\n", prop.ID, prop.Name, len(floors))

	// Check if user is a manager of this property
	var isManager bool
	err = db.QueryRow(`
		SELECT EXISTS(
			SELECT 1 FROM takes_care_of 
			WHERE uid = ? AND pid = ?
		)`, userID, propertyID).Scan(&isManager)
	
	if err != nil {
		fmt.Printf("Error checking manager status: %v\n", err)
		isManager = false
	}

	fmt.Printf("User %d is manager of property %d: %v\n", userID, propertyID, isManager)

	response := SinglePropertyResponse{
		Success: true,
		Message: "Property retrieved successfully",
		Property: prop,
		Floors: floors,
		IsManager: isManager,
	}

	// Log the response
	responseJSON, _ := json.MarshalIndent(response, "", "  ")
	fmt.Printf("Sending response: %s\n", string(responseJSON))

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// HandlePropertyRoutes handles all property-related routes
func HandlePropertyRoutes(w http.ResponseWriter, r *http.Request) {
	pathParts := strings.Split(r.URL.Path, "/")
	
	// Remove empty strings from path parts
	var cleanParts []string
	for _, part := range pathParts {
		if part != "" {
			cleanParts = append(cleanParts, part)
		}
	}

	// Handle different routes
	switch {
	case len(cleanParts) == 1 && cleanParts[0] == "property":
		// /property
		GetUserPropertiesHandler(w, r)
	case len(cleanParts) == 2 && cleanParts[0] == "property":
		if cleanParts[1] == "tenant" {
			// /property/tenant
			GetUserTenantPropertiesHandler(w, r)
		} else {
			// /property/{id}
			GetPropertyByIDHandler(w, r)
		}
	case len(cleanParts) == 3 && cleanParts[0] == "property" && cleanParts[2] == "floor":
		// /property/{id}/floor
		switch r.Method {
		case http.MethodGet:
			GetFloorsHandler(w, r)
		case http.MethodPost:
			AddFloorHandler(w, r)
		default:
			w.WriteHeader(http.StatusMethodNotAllowed)
			json.NewEncoder(w).Encode(FloorResponse{false, "Method not allowed", 0})
		}
	case len(cleanParts) == 4 && cleanParts[0] == "property" && cleanParts[2] == "floor":
		// /property/{id}/floor/{floor_id}
		switch r.Method {
		case http.MethodGet:
			GetFloorByIDHandler(w, r)
		case http.MethodPut:
			UpdateFloorHandler(w, r)
		case http.MethodPost:
			SendTenantRequestHandler(w, r)
		default:
			w.WriteHeader(http.StatusMethodNotAllowed)
			json.NewEncoder(w).Encode(FloorResponse{false, "Method not allowed", 0})
		}
	case len(cleanParts) == 5 && cleanParts[0] == "property" && cleanParts[2] == "floor" && cleanParts[4] == "payment":
		// /property/{id}/floor/{floor_id}/payment
		switch r.Method {
		case http.MethodPost:
			CreatePaymentHandler(w, r)
		default:
			w.WriteHeader(http.StatusMethodNotAllowed)
			json.NewEncoder(w).Encode(PaymentResponse{false, "Method not allowed", 0})
		}
	default:
		http.NotFound(w, r)
	}
}

func AddFloorHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("\n=== New Add Floor Request ===")
	fmt.Printf("Method: %s\n", r.Method)
	fmt.Printf("URL: %s\n", r.URL)

	// Set response header to JSON
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(FloorResponse{false, "Method not allowed", 0})
		return
	}

	// Get user ID from session
	userID := getUserIDFromSession(r)
	if userID == 0 {
		fmt.Println("No user ID found in session")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(FloorResponse{false, "User not authenticated", 0})
		return
	}

	// Extract property ID from URL
	pathParts := strings.Split(r.URL.Path, "/")
	var cleanParts []string
	for _, part := range pathParts {
		if part != "" {
			cleanParts = append(cleanParts, part)
		}
	}

	if len(cleanParts) != 3 {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(FloorResponse{false, "Invalid URL format", 0})
		return
	}

	propertyID, err := strconv.ParseInt(cleanParts[1], 10, 64)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(FloorResponse{false, "Invalid property ID", 0})
		return
	}

	var req FloorRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(FloorResponse{false, "Invalid request body", 0})
		return
	}

	if req.Name == "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(FloorResponse{false, "Floor name is required", 0})
		return
	}

	db, err := config.GetDBConnection()
	if err != nil {
		fmt.Printf("Database connection error: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(FloorResponse{false, "Database connection error", 0})
		return
	}

	// Verify user has access to the property
	var exists bool
	err = db.QueryRow(`
		SELECT EXISTS(
			SELECT 1 FROM takes_care_of 
			WHERE pid = ? AND uid = ?
		)`, propertyID, userID).Scan(&exists)
	
	if err != nil || !exists {
		w.WriteHeader(http.StatusForbidden)
		json.NewEncoder(w).Encode(FloorResponse{false, "Access denied to property", 0})
		return
	}

	// Generate random ID for floor
	floorID, err := utils.GenerateRandomID()
	if err != nil {
		fmt.Printf("Error generating random ID: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(FloorResponse{false, "Error generating floor ID", 0})
		return
	}

	// Insert floor into database
	_, err = db.Exec(`
		INSERT INTO floor (id, name, rent, created_at, created_by, updated_at, updated_by, pid)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
		floorID,
		req.Name,
		req.Rent,
		time.Now().In(time.FixedZone("BDT", 6*60*60)).Format("2006-01-02 15:04:05"),
		userID,
		time.Now().In(time.FixedZone("BDT", 6*60*60)).Format("2006-01-02 15:04:05"),
		userID,
		propertyID,
	)
	if err != nil {
		fmt.Printf("Error inserting floor: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(FloorResponse{false, "Error adding floor", 0})
		return
	}

	fmt.Printf("Successfully added floor ID: %d to property ID: %d\n", floorID, propertyID)

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(FloorResponse{
		Success: true,
		Message: "Floor added successfully",
		FloorID: floorID,
	})
}

// GetFloorsHandler handles GET requests for floors of a property
func GetFloorsHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("\n=== New Get Floors Request ===")
	fmt.Printf("Method: %s\n", r.Method)
	fmt.Printf("URL: %s\n", r.URL)

	// Set response header to JSON
	w.Header().Set("Content-Type", "application/json")

	// Get user ID from session
	userID := getUserIDFromSession(r)
	if userID == 0 {
		fmt.Println("No user ID found in session")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(FloorResponse{false, "User not authenticated", 0})
		return
	}

	// Extract property ID from URL
	pathParts := strings.Split(r.URL.Path, "/")
	var cleanParts []string
	for _, part := range pathParts {
		if part != "" {
			cleanParts = append(cleanParts, part)
		}
	}

	if len(cleanParts) != 3 {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(FloorResponse{false, "Invalid URL format", 0})
		return
	}

	propertyID, err := strconv.ParseInt(cleanParts[1], 10, 64)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(FloorResponse{false, "Invalid property ID", 0})
		return
	}

	db, err := config.GetDBConnection()
	if err != nil {
		fmt.Printf("Database connection error: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(FloorResponse{false, "Database connection error", 0})
		return
	}

	// Verify user has access to the property
	var exists bool
	err = db.QueryRow(`
		SELECT EXISTS(
			SELECT 1 FROM takes_care_of 
			WHERE pid = ? AND uid = ?
		)`, propertyID, userID).Scan(&exists)
	
	if err != nil || !exists {
		w.WriteHeader(http.StatusForbidden)
		json.NewEncoder(w).Encode(FloorResponse{false, "Access denied to property", 0})
		return
	}

	// Get all floors for this property
	rows, err := db.Query(`
		SELECT f.id, f.name, f.rent, f.created_at, f.tenant,
		       EXISTS(
		           SELECT 1 FROM notification n 
		           WHERE n.fid = f.id AND n.status = 'pending'
		       ) as has_pending_request
		FROM floor f
		WHERE f.pid = ?
		ORDER BY f.created_at DESC`, propertyID)
	
	if err != nil {
		fmt.Printf("Error querying floors: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(FloorResponse{false, "Error fetching floors", 0})
		return
	}
	defer rows.Close()

	var floors []Floor
	for rows.Next() {
		var floor Floor
		var tenant sql.NullInt64
		var hasPendingRequest bool
		if err := rows.Scan(&floor.ID, &floor.Name, &floor.Rent, &floor.CreatedAt, &tenant, &hasPendingRequest); err != nil {
			fmt.Printf("Error scanning floor row: %v\n", err)
			continue
		}
		if tenant.Valid {
			floor.Tenant = &tenant.Int64
		}
		if hasPendingRequest {
			floor.Status = "pending"
		}
		floors = append(floors, floor)
	}

	fmt.Printf("Found %d floors for property ID: %d\n", len(floors), propertyID)

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"message": "Floors retrieved successfully",
		"floors": floors,
	})
}

// GetFloorByIDHandler handles GET requests for a specific floor
func GetFloorByIDHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("\n=== New Get Floor By ID Request ===")
	fmt.Printf("Method: %s\n", r.Method)
	fmt.Printf("URL: %s\n", r.URL)

	// Set response header to JSON
	w.Header().Set("Content-Type", "application/json")

	// Get user ID from session
	userID := getUserIDFromSession(r)
	if userID == 0 {
		fmt.Println("No user ID found in session")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(FloorResponse{false, "User not authenticated", 0})
		return
	}

	// Extract property ID and floor ID from URL
	pathParts := strings.Split(r.URL.Path, "/")
	var cleanParts []string
	for _, part := range pathParts {
		if part != "" {
			cleanParts = append(cleanParts, part)
		}
	}

	if len(cleanParts) != 4 {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(FloorResponse{false, "Invalid URL format", 0})
		return
	}

	propertyID, err := strconv.ParseInt(cleanParts[1], 10, 64)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(FloorResponse{false, "Invalid property ID", 0})
		return
	}

	floorID, err := strconv.ParseInt(cleanParts[3], 10, 64)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(FloorResponse{false, "Invalid floor ID", 0})
		return
	}

	db, err := config.GetDBConnection()
	if err != nil {
		fmt.Printf("Database connection error: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(FloorResponse{false, "Database connection error", 0})
		return
	}

	// Verify user has access to the property
	var exists bool
	err = db.QueryRow(`
		SELECT EXISTS(
			SELECT 1 FROM takes_care_of 
			WHERE pid = ? AND uid = ?
		)`, propertyID, userID).Scan(&exists)
	
	if err != nil || !exists {
		w.WriteHeader(http.StatusForbidden)
		json.NewEncoder(w).Encode(FloorResponse{false, "Access denied to property", 0})
		return
	}

	// Get floor details
	var floor Floor
	var tenant sql.NullInt64
	err = db.QueryRow(`
		SELECT id, name, rent, created_at, tenant
		FROM floor
		WHERE id = ? AND pid = ?`, floorID, propertyID).Scan(
		&floor.ID, &floor.Name, &floor.Rent, &floor.CreatedAt, &tenant)
	
	if err != nil {
		fmt.Printf("Error querying floor: %v\n", err)
		w.WriteHeader(http.StatusNotFound)
		json.NewEncoder(w).Encode(FloorResponse{false, "Floor not found", 0})
		return
	}

	if tenant.Valid {
		floor.Tenant = &tenant.Int64
	}

	fmt.Printf("Found floor: ID=%d, Name=%s\n", floor.ID, floor.Name)

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"message": "Floor retrieved successfully",
		"floor": floor,
	})
}

// UpdateFloorHandler handles PUT requests to update a floor
func UpdateFloorHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("\n=== New Update Floor Request ===")
	fmt.Printf("Method: %s\n", r.Method)
	fmt.Printf("URL: %s\n", r.URL)

	// Set response header to JSON
	w.Header().Set("Content-Type", "application/json")

	// Get user ID from session
	userID := getUserIDFromSession(r)
	if userID == 0 {
		fmt.Println("No user ID found in session")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(FloorResponse{false, "User not authenticated", 0})
		return
	}

	// Extract property ID and floor ID from URL
	pathParts := strings.Split(r.URL.Path, "/")
	var cleanParts []string
	for _, part := range pathParts {
		if part != "" {
			cleanParts = append(cleanParts, part)
		}
	}

	if len(cleanParts) != 4 {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(FloorResponse{false, "Invalid URL format", 0})
		return
	}

	propertyID, err := strconv.ParseInt(cleanParts[1], 10, 64)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(FloorResponse{false, "Invalid property ID", 0})
		return
	}

	floorID, err := strconv.ParseInt(cleanParts[3], 10, 64)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(FloorResponse{false, "Invalid floor ID", 0})
		return
	}

	var req FloorRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(FloorResponse{false, "Invalid request body", 0})
		return
	}

	if req.Name == "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(FloorResponse{false, "Floor name is required", 0})
		return
	}

	db, err := config.GetDBConnection()
	if err != nil {
		fmt.Printf("Database connection error: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(FloorResponse{false, "Database connection error", 0})
		return
	}

	// Verify user has access to the property
	var exists bool
	err = db.QueryRow(`
		SELECT EXISTS(
			SELECT 1 FROM takes_care_of 
			WHERE pid = ? AND uid = ?
		)`, propertyID, userID).Scan(&exists)
	
	if err != nil || !exists {
		w.WriteHeader(http.StatusForbidden)
		json.NewEncoder(w).Encode(FloorResponse{false, "Access denied to property", 0})
		return
	}

	// Update floor
	_, err = db.Exec(`
		UPDATE floor 
		SET name = ?, rent = ?, tenant = ?, updated_at = ?, updated_by = ?
		WHERE id = ? AND pid = ?`,
		req.Name, req.Rent, req.Tenant, time.Now().In(time.FixedZone("BDT", 6*60*60)).Format("2006-01-02 15:04:05"), userID, floorID, propertyID)
	
	if err != nil {
		fmt.Printf("Error updating floor: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(FloorResponse{false, "Error updating floor", 0})
		return
	}

	// If tenant is being added, create a payment record
	if req.Tenant != nil {
		// Generate random ID for payment
		paymentID, err := utils.GenerateRandomID()
		if err != nil {
			fmt.Printf("Error generating payment ID: %v\n", err)
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(FloorResponse{false, "Error generating payment ID", 0})
			return
		}

		// Insert payment record
		_, err = db.Exec(`
			INSERT INTO payment (
				id, due_rent, due_electrictiy_bill, recieved_money, 
				full_payment, created_at, created_by, updated_at, updated_by,
				fid, uid
			) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
			paymentID,
			0, // due_rent
			0, // due_electricity_bill
			0, // received_money
			true, // full_payment
			time.Now().In(time.FixedZone("BDT", 6*60*60)).Format("2006-01-02 15:04:05"),
			userID,
			time.Now().In(time.FixedZone("BDT", 6*60*60)).Format("2006-01-02 15:04:05"),
			userID,
			floorID,
			*req.Tenant,
		)

		if err != nil {
			fmt.Printf("Error creating payment record: %v\n", err)
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(FloorResponse{false, fmt.Sprintf("Error creating payment record: %v", err), 0})
			return
		}

		fmt.Printf("Successfully created payment record for floor ID: %d and tenant ID: %d\n", floorID, *req.Tenant)
	}

	fmt.Printf("Successfully updated floor ID: %d\n", floorID)

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(FloorResponse{
		Success: true,
		Message: "Floor updated successfully",
		FloorID: floorID,
	})
}

// GetUserPhonesHandler handles GET requests for all users' phone numbers
func GetUserPhonesHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("\n=== New Get User Phones Request ===")
	fmt.Printf("Method: %s\n", r.Method)
	fmt.Printf("URL: %s\n", r.URL)

	// Set response header to JSON
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodGet {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(UserPhonesResponse{false, "Method not allowed", nil})
		return
	}

	// Get user ID from session
	userID := getUserIDFromSession(r)
	if userID == 0 {
		fmt.Println("No user ID found in session")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(UserPhonesResponse{false, "User not authenticated", nil})
		return
	}

	db, err := config.GetDBConnection()
	if err != nil {
		fmt.Printf("Database connection error: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(UserPhonesResponse{false, "Database connection error", nil})
		return
	}

	// Query to get all users' phone numbers
	query := `
		SELECT id, phone_number 
		FROM user 
		WHERE phone_number IS NOT NULL AND phone_number != ''
		ORDER BY id DESC`
	
	fmt.Printf("Executing query: %s\n", query)
	
	rows, err := db.Query(query)
	if err != nil {
		fmt.Printf("Error querying users: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(UserPhonesResponse{false, "Error fetching users", nil})
		return
	}
	defer rows.Close()

	var users []UserPhone
	for rows.Next() {
		var user UserPhone
		if err := rows.Scan(&user.ID, &user.Phone); err != nil {
			fmt.Printf("Error scanning user row: %v\n", err)
			continue
		}
		users = append(users, user)
		fmt.Printf("Found user: ID=%d, Phone=%s\n", user.ID, user.Phone)
	}

	if err = rows.Err(); err != nil {
		fmt.Printf("Error iterating user rows: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(UserPhonesResponse{false, "Error processing users", nil})
		return
	}

	fmt.Printf("Found %d users with phone numbers\n", len(users))

	response := UserPhonesResponse{
		Success: true,
		Message: "Users retrieved successfully",
		Users:   users,
	}

	// Log the response
	responseJSON, _ := json.MarshalIndent(response, "", "  ")
	fmt.Printf("Sending response: %s\n", string(responseJSON))

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// GetUserIDByPhoneHandler handles GET requests to get user ID by phone number
func GetUserIDByPhoneHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("\n=== New Get User ID By Phone Request ===")
	fmt.Printf("Method: %s\n", r.Method)
	fmt.Printf("URL: %s\n", r.URL)

	// Set response header to JSON
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodGet {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(UserIDResponse{false, "Method not allowed", 0})
		return
	}

	// Get user ID from session
	userID := getUserIDFromSession(r)
	if userID == 0 {
		fmt.Println("No user ID found in session")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(UserIDResponse{false, "User not authenticated", 0})
		return
	}

	// Extract phone number from URL
	pathParts := strings.Split(r.URL.Path, "/")
	var cleanParts []string
	for _, part := range pathParts {
		if part != "" {
			cleanParts = append(cleanParts, part)
		}
	}

	if len(cleanParts) != 3 {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(UserIDResponse{false, "Invalid URL format", 0})
		return
	}

	phoneNumber := cleanParts[2]
	if phoneNumber == "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(UserIDResponse{false, "Phone number is required", 0})
		return
	}

	db, err := config.GetDBConnection()
	if err != nil {
		fmt.Printf("Database connection error: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(UserIDResponse{false, "Database connection error", 0})
		return
	}

	// Query to get user ID by phone number
	var foundUserID int64
	err = db.QueryRow(`
		SELECT id 
		FROM user 
		WHERE phone_number = ?`, phoneNumber).Scan(&foundUserID)
	
	if err != nil {
		if err == sql.ErrNoRows {
			fmt.Printf("No user found with phone number: %s\n", phoneNumber)
			w.WriteHeader(http.StatusNotFound)
			json.NewEncoder(w).Encode(UserIDResponse{false, "User not found", 0})
			return
		}
		fmt.Printf("Error querying user: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(UserIDResponse{false, "Error fetching user", 0})
		return
	}

	fmt.Printf("Found user ID: %d for phone number: %s\n", foundUserID, phoneNumber)

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(UserIDResponse{
		Success: true,
		Message: "User ID retrieved successfully",
		UserID:  foundUserID,
	})
}

// CreatePaymentHandler handles POST requests to create a payment record
func CreatePaymentHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("\n=== New Create Payment Request ===")
	fmt.Printf("Method: %s\n", r.Method)
	fmt.Printf("URL: %s\n", r.URL)

	// Set response header to JSON
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(PaymentResponse{false, "Method not allowed", 0})
		return
	}

	// Get user ID from session
	userID := getUserIDFromSession(r)
	fmt.Printf("User ID from session: %d\n", userID)
	if userID == 0 {
		fmt.Println("No user ID found in session")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(PaymentResponse{false, "User not authenticated", 0})
		return
	}

	// Extract property ID and floor ID from URL
	pathParts := strings.Split(r.URL.Path, "/")
	var cleanParts []string
	for _, part := range pathParts {
		if part != "" {
			cleanParts = append(cleanParts, part)
		}
	}

	fmt.Printf("URL parts: %v\n", cleanParts)

	if len(cleanParts) != 5 {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(PaymentResponse{false, "Invalid URL format", 0})
		return
	}

	propertyID, err := strconv.ParseInt(cleanParts[1], 10, 64)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(PaymentResponse{false, "Invalid property ID", 0})
		return
	}

	floorID, err := strconv.ParseInt(cleanParts[3], 10, 64)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(PaymentResponse{false, "Invalid floor ID", 0})
		return
	}

	fmt.Printf("Property ID: %d, Floor ID: %d\n", propertyID, floorID)

	var req PaymentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		fmt.Printf("Error decoding request body: %v\n", err)
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(PaymentResponse{false, "Invalid request body", 0})
		return
	}

	fmt.Printf("Request body: %+v\n", req)

	db, err := config.GetDBConnection()
	if err != nil {
		fmt.Printf("Database connection error: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(PaymentResponse{false, "Database connection error", 0})
		return
	}

	// Check if user is a manager of the property
	var isManager bool
	managerQuery := "SELECT EXISTS(SELECT 1 FROM takes_care_of WHERE uid = ? AND pid = ?)"
	fmt.Printf("Executing manager check query: %s with userID: %d, propertyID: %d\n", managerQuery, userID, propertyID)
	
	err = db.QueryRow(managerQuery, userID, propertyID).Scan(&isManager)
	if err != nil {
		fmt.Printf("Error checking manager status: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(PaymentResponse{false, "Database error", 0})
		return
	}

	fmt.Printf("Is user %d manager of property %d: %v\n", userID, propertyID, isManager)

	if !isManager {
		w.WriteHeader(http.StatusForbidden)
		json.NewEncoder(w).Encode(PaymentResponse{false, "Only managers can create payments", 0})
		return
	}

	// Get tenant ID from floor
	var tenantID int64
	err = db.QueryRow(`
		SELECT tenant 
		FROM floor 
		WHERE id = ? AND pid = ?`, floorID, propertyID).Scan(&tenantID)
	
	if err != nil {
		fmt.Printf("Error getting tenant ID: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(PaymentResponse{false, "Error getting tenant information", 0})
		return
	}

	if tenantID == 0 {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(PaymentResponse{false, "No tenant assigned to this floor", 0})
		return
	}

	// Calculate total due amount
	totalDue := req.DueRent + req.DueElectricityBill
	
	// Calculate after_receiving_money
	afterReceivingMoney := req.ReceivedMoney - totalDue
	
	// Set full_payment based on after_receiving_money
	fullPayment := afterReceivingMoney == 0

	fmt.Printf("Total due: %d, Received: %d, After receiving: %d, Full payment: %v\n", 
		totalDue, req.ReceivedMoney, afterReceivingMoney, fullPayment)

	// Generate random ID for payment
	paymentID, err := utils.GenerateRandomID()
	if err != nil {
		fmt.Printf("Error generating payment ID: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(PaymentResponse{false, "Error generating payment ID", 0})
		return
	}

	// Insert payment record
	_, err = db.Exec(`
		INSERT INTO payment (
			id, due_rent, due_electrictiy_bill, recieved_money, 
			full_payment, created_at, created_by, updated_at, updated_by,
			fid, uid
		) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		paymentID,
		req.DueRent,
		req.DueElectricityBill,
		req.ReceivedMoney,
		fullPayment,
		time.Now().In(time.FixedZone("BDT", 6*60*60)).Format("2006-01-02 15:04:05"),
		userID,
		time.Now().In(time.FixedZone("BDT", 6*60*60)).Format("2006-01-02 15:04:05"),
		userID,
		floorID,
		tenantID,
	)

	if err != nil {
		fmt.Printf("Error creating payment record: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(PaymentResponse{false, fmt.Sprintf("Error creating payment record: %v", err), 0})
		return
	}

	fmt.Printf("Successfully created payment record ID: %d for floor ID: %d and tenant ID: %d\n", paymentID, floorID, tenantID)

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(PaymentResponse{
		Success:   true,
		Message:   "Payment record created successfully",
		PaymentID: paymentID,
	})
}

// SendTenantRequestHandler handles POST requests to send a tenant request
func SendTenantRequestHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("\n=== New Send Tenant Request ===")
	fmt.Printf("Method: %s\n", r.Method)
	fmt.Printf("URL: %s\n", r.URL)

	// Set response header to JSON
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(TenantRequestResponse{false, "Method not allowed"})
		return
	}

	// Get user ID from session
	userID := getUserIDFromSession(r)
	if userID == 0 {
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(TenantRequestResponse{false, "User not authenticated"})
		return
	}

	// Extract property ID and floor ID from URL using Gorilla Mux's Vars
	vars := mux.Vars(r)
	propertyID, err := strconv.ParseInt(vars["id"], 10, 64)
	if err != nil {
		http.Error(w, "Invalid property ID", http.StatusBadRequest)
		return
	}

	floorID, err := strconv.ParseInt(vars["floor_id"], 10, 64)
	if err != nil {
		http.Error(w, "Invalid floor ID", http.StatusBadRequest)
		return
	}

	// Get phone number from request body
	var req struct {
		PhoneNumber string `json:"phone_number"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(TenantRequestResponse{false, "Invalid request body"})
		return
	}

	if req.PhoneNumber == "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(TenantRequestResponse{false, "Phone number is required"})
		return
	}

	db, err := config.GetDBConnection()
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(TenantRequestResponse{false, "Database connection error"})
		return
	}

	// Check if user is a manager of the property
	var isManager bool
	err = db.QueryRow(`
		SELECT EXISTS(
			SELECT 1 FROM takes_care_of 
			WHERE uid = ? AND pid = ?
		)`, userID, propertyID).Scan(&isManager)
	
	if err != nil || !isManager {
		w.WriteHeader(http.StatusForbidden)
		json.NewEncoder(w).Encode(TenantRequestResponse{false, "Only managers can send tenant requests"})
		return
	}

	// Get property and floor details
	var propertyName, floorName string
	err = db.QueryRow(`
		SELECT p.name, f.name
		FROM property p
		JOIN floor f ON p.id = f.pid
		WHERE p.id = ? AND f.id = ?`, propertyID, floorID).Scan(&propertyName, &floorName)
	
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(TenantRequestResponse{false, "Error getting property details"})
		return
	}

	// Get tenant ID from phone number
	var tenantID int64
	err = db.QueryRow(`
		SELECT id FROM user 
		WHERE phone_number = ?`, req.PhoneNumber).Scan(&tenantID)
	
	if err != nil {
		if err == sql.ErrNoRows {
			w.WriteHeader(http.StatusNotFound)
			json.NewEncoder(w).Encode(TenantRequestResponse{false, "User not found with this phone number"})
			return
		}
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(TenantRequestResponse{false, "Error finding user"})
		return
	}

	// Check if there's already a pending notification for this floor
	var pendingExists bool
	err = db.QueryRow(`
		SELECT EXISTS(
			SELECT 1 FROM notification 
			WHERE fid = ? AND status = 'pending'
		)`, floorID).Scan(&pendingExists)
	
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(TenantRequestResponse{false, "Error checking pending notifications"})
		return
	}

	if pendingExists {
		w.WriteHeader(http.StatusConflict)
		json.NewEncoder(w).Encode(TenantRequestResponse{false, "A pending request already exists for this floor"})
		return
	}

	// Generate notification ID
	notificationID, err := utils.GenerateRandomID()
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(TenantRequestResponse{false, "Error generating notification ID"})
		return
	}

	// Create notification message
	message := fmt.Sprintf("Tenant request for %s - %s", propertyName, floorName)

	// Insert notification
	_, err = db.Exec(`
		INSERT INTO notification (
			id, message, sender, receiver, pid, fid,
			status, created_at, created_by, updated_at, updated_by
		) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		notificationID,
		message,
		userID,
		tenantID,
		propertyID,
		floorID,
		"pending",
		time.Now().In(time.FixedZone("BDT", 6*60*60)).Format("2006-01-02 15:04:05"),
		userID,
		time.Now().In(time.FixedZone("BDT", 6*60*60)).Format("2006-01-02 15:04:05"),
		userID,
	)

	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(TenantRequestResponse{false, "Error creating notification"})
		return
	}

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(TenantRequestResponse{
		Success: true,
		Message: "Tenant request sent successfully",
	})
}

// GetUserNotificationsHandler handles GET requests to get all notifications for a user
func GetUserNotificationsHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("\n=== New Get User Notifications Request ===")
	fmt.Printf("Method: %s\n", r.Method)
	fmt.Printf("URL: %s\n", r.URL)

	// Set response header to JSON
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodGet {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(NotificationsResponse{false, "Method not allowed", nil})
		return
	}

	// Get user ID from session
	userID := getUserIDFromSession(r)
	if userID == 0 {
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(NotificationsResponse{false, "User not authenticated", nil})
		return
	}

	db, err := config.GetDBConnection()
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(NotificationsResponse{false, "Database connection error", nil})
		return
	}

	// Get all notifications for the user
	query := `
		SELECT 
			n.id, n.message, n.status, n.created_at,
			p.id as property_id, p.name as property_name,
			f.id as floor_id, f.name as floor_name,
			CASE 
				WHEN n.message LIKE 'Tenant request%' AND n.status = 'pending' THEN true
				ELSE false
			END as show_actions
		FROM notification n
		JOIN property p ON n.pid = p.id
		JOIN floor f ON n.fid = f.id
		WHERE n.receiver = ?
		ORDER BY n.created_at DESC
	`
	
	rows, err := db.Query(query, userID)
	if err != nil {
		fmt.Printf("Error querying notifications: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(NotificationsResponse{false, "Error fetching notifications", nil})
		return
	}
	defer rows.Close()

	var notifications []Notification
	for rows.Next() {
		var n Notification
		if err := rows.Scan(
			&n.ID, &n.Message, &n.Status, &n.CreatedAt,
			&n.Property.ID, &n.Property.Name,
			&n.Floor.ID, &n.Floor.Name,
			&n.ShowActions,
		); err != nil {
			fmt.Printf("Error scanning notification row: %v\n", err)
			continue
		}
		notifications = append(notifications, n)
	}

	if err = rows.Err(); err != nil {
		fmt.Printf("Error iterating notification rows: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(NotificationsResponse{false, "Error processing notifications", nil})
		return
	}

	fmt.Printf("Found %d notifications for user %d\n", len(notifications), userID)

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(NotificationsResponse{
		Success:       true,
		Message:       "Notifications retrieved successfully",
		Notifications: notifications,
	})
}

// DeleteNotificationHandler handles DELETE requests to remove a notification
func DeleteNotificationHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("\n=== New Delete Notification Request ===")
	fmt.Printf("Method: %s\n", r.Method)
	fmt.Printf("URL: %s\n", r.URL)

	// Set response header to JSON
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodDelete {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(TenantRequestResponse{false, "Method not allowed"})
		return
	}

	// Get user ID from session
	userID := getUserIDFromSession(r)
	if userID == 0 {
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(TenantRequestResponse{false, "User not authenticated"})
		return
	}

	// Extract notification ID from URL
	pathParts := strings.Split(r.URL.Path, "/")
	var cleanParts []string
	for _, part := range pathParts {
		if part != "" {
			cleanParts = append(cleanParts, part)
		}
	}

	if len(cleanParts) != 3 {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(TenantRequestResponse{false, "Invalid URL format"})
		return
	}

	notificationID, err := strconv.ParseInt(cleanParts[2], 10, 64)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(TenantRequestResponse{false, "Invalid notification ID"})
		return
	}

	db, err := config.GetDBConnection()
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(TenantRequestResponse{false, "Database connection error"})
		return
	}

	// Check if user is the sender of the notification and if it's pending
	var isSender bool
	err = db.QueryRow(`
		SELECT EXISTS(
			SELECT 1 FROM notification 
			WHERE id = ? AND sender = ? AND status = 'pending'
		)`, notificationID, userID).Scan(&isSender)
	
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(TenantRequestResponse{false, "Error checking notification"})
		return
	}

	if !isSender {
		w.WriteHeader(http.StatusForbidden)
		json.NewEncoder(w).Encode(TenantRequestResponse{false, "You can only delete your own pending notifications"})
		return
	}

	// Delete the notification
	_, err = db.Exec(`
		DELETE FROM notification 
		WHERE id = ? AND sender = ? AND status = 'pending'`,
		notificationID, userID)
	
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(TenantRequestResponse{false, "Error deleting notification"})
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(TenantRequestResponse{
		Success: true,
		Message: "Notification deleted successfully",
	})
}

// SendMonthlyNotifications sends notifications to all tenants on the 5th of each month
func SendMonthlyNotifications() {
	// Get current date in Bangladesh timezone
	loc, _ := time.LoadLocation("Asia/Dhaka")
	now := time.Now().In(loc)

	// Only send notifications on the 5th of each month
	if now.Day() != 5 {
		return
	}

	fmt.Println("=== Sending Monthly Notifications ===")

	// Get database connection
	db, err := config.GetDBConnection()
	if err != nil {
		fmt.Printf("Database connection error: %v\n", err)
		return
	}

	// Get all floors with tenants
	query := `
		SELECT f.id, f.pid, f.tenant, p.name as property_name
		FROM floor f
		JOIN property p ON f.pid = p.id
		WHERE f.tenant IS NOT NULL
	`
	rows, err := db.Query(query)
	if err != nil {
		fmt.Printf("Error querying floors: %v\n", err)
		return
	}
	defer rows.Close()

	// Process each floor
	for rows.Next() {
		var floorID, propertyID, tenantID int
		var propertyName string
		if err := rows.Scan(&floorID, &propertyID, &tenantID, &propertyName); err != nil {
			fmt.Printf("Error scanning floor: %v\n", err)
			continue
		}

		// Get latest payment for this floor
		var dueRent, dueElectricity, receivedMoney float64
		paymentQuery := `
			SELECT due_rent, due_electrictiy_bill, recieved_money
			FROM payment
			WHERE fid = ?
			ORDER BY created_at DESC
			LIMIT 1
		`
		err := db.QueryRow(paymentQuery, floorID).Scan(&dueRent, &dueElectricity, &receivedMoney)
		if err != nil && err != sql.ErrNoRows {
			fmt.Printf("Error querying payment: %v\n", err)
			continue
		}

		// Calculate due payment
		duePayment := dueRent + dueElectricity - receivedMoney

		// Create notification
		notificationQuery := `
			INSERT INTO notification (pid, receiver, message, created_at)
			VALUES (?, ?, ?, NOW())
		`
		message := fmt.Sprintf("Monthly rent reminder for %s:\nDue Rent: ৳%.2f\nDue Electricity: ৳%.2f\nReceived Money: ৳%.2f\nDue Payment: ৳%.2f",
			propertyName, dueRent, dueElectricity, receivedMoney, duePayment)

		_, err = db.Exec(notificationQuery, propertyID, tenantID, message)
		if err != nil {
			fmt.Printf("Error creating notification: %v\n", err)
			continue
		}

		fmt.Printf("Created notification for tenant %d in property %s\n", tenantID, propertyName)
	}

	fmt.Println("Monthly notifications sent successfully.")
}

// HandleTenantRequestAction handles POST requests to accept/reject tenant requests
func HandleTenantRequestAction(w http.ResponseWriter, r *http.Request) {
	fmt.Println("\n=== New Tenant Request Action ===")
	fmt.Printf("Method: %s\n", r.Method)
	fmt.Printf("URL: %s\n", r.URL)

	// Set response header to JSON
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(TenantRequestResponse{false, "Method not allowed"})
		return
	}

	// Get user ID from session
	userID := getUserIDFromSession(r)
	if userID == 0 {
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(TenantRequestResponse{false, "User not authenticated"})
		return
	}

	// Parse request body
	var request struct {
		NotificationID int64 `json:"notification_id"`
		Accept        bool  `json:"accept"`
	}

	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Get database connection
	db, err := config.GetDBConnection()
	if err != nil {
		fmt.Printf("Database connection error: %v\n", err)
		http.Error(w, "Database connection failed", http.StatusInternalServerError)
		return
	}
	if db == nil {
		http.Error(w, "Database connection is nil", http.StatusInternalServerError)
		return
	}

	// Start transaction
	tx, err := db.Begin()
	if err != nil {
		fmt.Printf("Transaction start error: %v\n", err)
		http.Error(w, "Failed to start transaction", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()

	// Get notification details
	var notification struct {
		ID      int64
		Message string
		Status  string
		FloorID int64
		PID     int64
		Sender  int64
		Receiver int64
	}

	err = tx.QueryRow(`
		SELECT n.id, n.message, n.status, n.fid, n.pid, n.sender, n.receiver
		FROM notification n
		WHERE n.id = ? AND n.receiver = ?
	`, request.NotificationID, userID).Scan(
		&notification.ID,
		&notification.Message,
		&notification.Status,
		&notification.FloorID,
		&notification.PID,
		&notification.Sender,
		&notification.Receiver,
	)

	if err != nil {
		fmt.Printf("Error getting notification: %v\n", err)
		if err == sql.ErrNoRows {
			http.Error(w, "Notification not found", http.StatusNotFound)
		} else {
			http.Error(w, "Failed to get notification", http.StatusInternalServerError)
		}
		return
	}

	if notification.Status != "pending" {
		http.Error(w, "Notification is not pending", http.StatusBadRequest)
		return
	}

	// Update notification status
	newStatus := "rejected"
	if request.Accept {
		newStatus = "accepted"
	}

	_, err = tx.Exec(`
		UPDATE notification 
		SET status = ?, updated_at = NOW(), updated_by = ?
		WHERE id = ?
	`, newStatus, userID, request.NotificationID)

	if err != nil {
		fmt.Printf("Error updating notification: %v\n", err)
		http.Error(w, "Failed to update notification", http.StatusInternalServerError)
		return
	}

	// If accepted, update floor table
	if request.Accept {
		// Check if floor is already occupied
		var isOccupied bool
		err = tx.QueryRow(`
			SELECT COUNT(*) > 0
			FROM floor 
			WHERE id = ? AND tenant IS NOT NULL
		`, notification.FloorID).Scan(&isOccupied)

		if err != nil {
			fmt.Printf("Error checking floor status: %v\n", err)
			http.Error(w, "Failed to check floor status", http.StatusInternalServerError)
			return
		}

		if isOccupied {
			http.Error(w, "Floor is already occupied", http.StatusConflict)
			return
		}

		// Update floor with tenant (receiver of the notification, not sender)
		_, err = tx.Exec(`
			UPDATE floor 
			SET tenant = ?, updated_at = NOW(), updated_by = ?
			WHERE id = ?
		`, notification.Receiver, userID, notification.FloorID)

		if err != nil {
			fmt.Printf("Error updating floor: %v\n", err)
			http.Error(w, "Failed to update floor", http.StatusInternalServerError)
			return
		}
	}

	// Commit transaction
	if err = tx.Commit(); err != nil {
		fmt.Printf("Error committing transaction: %v\n", err)
		http.Error(w, "Failed to commit transaction", http.StatusInternalServerError)
		return
	}

	// Send response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"message": "Tenant request " + newStatus,
	})
}

// GetUserTenantPropertiesHandler handles GET requests to get all properties where the user is a tenant
func GetUserTenantPropertiesHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("\n=== New Get User Tenant Properties Request ===")
	fmt.Printf("Method: %s\n", r.Method)
	fmt.Printf("URL: %s\n", r.URL)

	// Set response header to JSON
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodGet {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(UserPropertiesResponse{false, "Method not allowed", nil})
		return
	}

	// Get user ID from session
	userID := getUserIDFromSession(r)
	if userID == 0 {
		fmt.Println("No user ID found in session")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(UserPropertiesResponse{false, "User not authenticated", nil})
		return
	}

	fmt.Printf("Fetching properties where user ID: %d is a tenant\n", userID)

	db, err := config.GetDBConnection()
	if err != nil {
		fmt.Printf("Database connection error: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(UserPropertiesResponse{false, "Database connection error", nil})
		return
	}

	// Query to get all properties where the user is a tenant
	query := `
		SELECT DISTINCT p.id, p.name, p.address, p.created_at 
		FROM property p
		INNER JOIN floor f ON p.id = f.pid
		WHERE f.tenant = ?
		ORDER BY p.created_at DESC`
	
	fmt.Printf("Executing query: %s with userID: %d\n", query, userID)
	
	rows, err := db.Query(query, userID)
	if err != nil {
		fmt.Printf("Error querying properties: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(UserPropertiesResponse{false, "Error fetching properties", nil})
		return
	}
	defer rows.Close()

	var properties []Property
	for rows.Next() {
		var prop Property
		if err := rows.Scan(&prop.ID, &prop.Name, &prop.Address, &prop.CreatedAt); err != nil {
			fmt.Printf("Error scanning property row: %v\n", err)
			continue
		}
		properties = append(properties, prop)
		fmt.Printf("Found property: ID=%d, Name=%s\n", prop.ID, prop.Name)
	}

	if err = rows.Err(); err != nil {
		fmt.Printf("Error iterating property rows: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(UserPropertiesResponse{false, "Error processing properties", nil})
		return
	}

	fmt.Printf("Found %d properties where user is a tenant\n", len(properties))

	response := UserPropertiesResponse{
		Success: true,
		Message: "Properties retrieved successfully",
		Properties: properties,
	}

	// Log the response
	responseJSON, _ := json.MarshalIndent(response, "", "  ")
	fmt.Printf("Sending response: %s\n", string(responseJSON))

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// RemoveTenantHandler handles POST requests to remove a tenant from a floor
func RemoveTenantHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(TenantRequestResponse{false, "Method not allowed"})
		return
	}

	// Get user ID from session
	userID := getUserIDFromSession(r)
	vars := mux.Vars(r)
	propertyID, err := strconv.ParseInt(vars["id"], 10, 64)
	if err != nil {
		http.Error(w, "Invalid property ID", http.StatusBadRequest)
		return
	}
	floorID, err := strconv.ParseInt(vars["floor_id"], 10, 64)
	if err != nil {
		http.Error(w, "Invalid floor ID", http.StatusBadRequest)
		return
	}

	if userID == 0 {
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(TenantRequestResponse{false, "User not authenticated"})
		return
	}

	// Get database connection
	db, err := config.GetDBConnection()
	if err != nil {
		fmt.Printf("Database connection error: %v\n", err)
		http.Error(w, "Database connection failed", http.StatusInternalServerError)
		return
	}
	if db == nil {
		http.Error(w, "Database connection is nil", http.StatusInternalServerError)
		return
	}

	// Start transaction
	tx, err := db.Begin()
	if err != nil {
		fmt.Printf("Transaction start error: %v\n", err)
		http.Error(w, "Failed to start transaction", http.StatusInternalServerError)
		return
	}
	defer tx.Rollback()

	// Check if user is the manager of the property
	var isManager bool
	err = tx.QueryRow(`
		SELECT EXISTS(
			SELECT 1 FROM takes_care_of 
			WHERE uid = ? AND pid = ?
		)`, userID, propertyID).Scan(&isManager)

	if err != nil {
		fmt.Printf("Error checking property manager: %v\n", err)
		http.Error(w, "Failed to check authorization", http.StatusInternalServerError)
		return
	}

	if !isManager {
		http.Error(w, "You are not authorized to manage this property", http.StatusForbidden)
		return
	}

	// Check if there's a tenant in the floor
	var hasTenant bool
	err = tx.QueryRow(`
		SELECT EXISTS(
			SELECT 1 FROM floor 
			WHERE id = ? AND pid = ? AND tenant IS NOT NULL
		)`, floorID, propertyID).Scan(&hasTenant)

	if err != nil {
		fmt.Printf("Error checking tenant: %v\n", err)
		http.Error(w, "Failed to check tenant", http.StatusInternalServerError)
		return
	}

	if !hasTenant {
		http.Error(w, "No tenant found in this floor", http.StatusBadRequest)
		return
	}

	// Update floor to remove tenant
	_, err = tx.Exec(`
		UPDATE floor 
		SET tenant = NULL, updated_at = NOW(), updated_by = ?
		WHERE id = ? AND pid = ?
	`, userID, floorID, propertyID)

	if err != nil {
		fmt.Printf("Error removing tenant: %v\n", err)
		http.Error(w, "Failed to remove tenant", http.StatusInternalServerError)
		return
	}

	// Commit transaction
	if err = tx.Commit(); err != nil {
		fmt.Printf("Error committing transaction: %v\n", err)
		http.Error(w, "Failed to commit transaction", http.StatusInternalServerError)
		return
	}

	// Send response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"message": "Tenant removed successfully",
	})
}

type ManagerCheckResponse struct {
	Success   bool   `json:"success"`
	Message   string `json:"message"`
	IsManager bool   `json:"is_manager"`
}

// CheckUserManagerHandler handles GET requests to check if user is a manager of a property
func CheckUserManagerHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Println("\n=== New Check User Manager Request ===")
	fmt.Printf("Method: %s\n", r.Method)
	fmt.Printf("URL: %s\n", r.URL)

	// Set response header to JSON
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodGet {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(ManagerCheckResponse{false, "Method not allowed", false})
		return
	}

	// Get user ID from session
	userID := getUserIDFromSession(r)
	if userID == 0 {
		fmt.Println("No user ID found in session")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(ManagerCheckResponse{false, "User not authenticated", false})
		return
	}

	// Extract property ID from URL
	pathParts := strings.Split(r.URL.Path, "/")
	var cleanParts []string
	for _, part := range pathParts {
		if part != "" {
			cleanParts = append(cleanParts, part)
		}
	}

	if len(cleanParts) != 3 {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(ManagerCheckResponse{false, "Invalid URL format", false})
		return
	}

	propertyID, err := strconv.ParseInt(cleanParts[1], 10, 64)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(ManagerCheckResponse{false, "Invalid property ID", false})
		return
	}

	fmt.Printf("Checking if user ID: %d is manager of property ID: %d\n", userID, propertyID)

	db, err := config.GetDBConnection()
	if err != nil {
		fmt.Printf("Database connection error: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(ManagerCheckResponse{false, "Database connection error", false})
		return
	}

	// Check if user is a manager of the property
	var isManager bool
	err = db.QueryRow(`
		SELECT EXISTS(
			SELECT 1 FROM takes_care_of 
			WHERE uid = ? AND pid = ?
		)`, userID, propertyID).Scan(&isManager)
	
	if err != nil {
		fmt.Printf("Error checking manager status: %v\n", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(ManagerCheckResponse{false, "Error checking manager status", false})
		return
	}

	fmt.Printf("User %d is manager of property %d: %v\n", userID, propertyID, isManager)

	response := ManagerCheckResponse{
		Success:   true,
		Message:   "Manager check completed",
		IsManager: isManager,
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
} 