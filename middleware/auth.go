package middleware

import (
	"context"
	
	"fmt"
	"go-rent/config"
	"go-rent/utils"
	"net/http"
	"strconv"
	"strings"
	"time"
)

// AuthMiddleware checks if the user is authenticated via session token
func AuthMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		fmt.Printf("\n=== Auth Middleware Check ===")
		fmt.Printf("Method: %s\n", r.Method)
		fmt.Printf("URL: %s\n", r.URL.Path)

		// Skip authentication for login and register endpoints
		if r.URL.Path == "/login" || r.URL.Path == "/register" {
			fmt.Println("Skipping auth for login/register endpoint")
			next.ServeHTTP(w, r)
			return
		}

		// Get session token from cookie
		cookie, err := r.Cookie("sessiontoken")
		if err != nil {
			fmt.Printf("No session token found: %v\n", err)
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusUnauthorized)
			fmt.Fprintf(w, `{"success":false,"message":"Authentication required"}`)
			return
		}

		// Validate the session token
		userID, err := utils.ValidateToken(cookie.Value)
		if err != nil {
			fmt.Printf("Invalid session token: %v\n", err)
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusUnauthorized)
			fmt.Fprintf(w, `{"success":false,"message":"Invalid or expired session"}`)
			return
		}

		if userID == 0 {
			fmt.Println("No user ID found in token")
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusUnauthorized)
			fmt.Fprintf(w, `{"success":false,"message":"Invalid session"}`)
			return
		}

		fmt.Printf("User authenticated: ID=%d\n", userID)
		
		// Add user ID to request context for handlers to use
		ctx := r.Context()
		ctx = context.WithValue(ctx, "userID", userID)
		r = r.WithContext(ctx)

		next.ServeHTTP(w, r)
	})
}

// ManagerMiddleware checks if the user is a manager of a specific property
func ManagerMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		fmt.Printf("\n=== Manager Middleware Check ===")
		
		// Get user ID from context (set by AuthMiddleware)
		userID, ok := r.Context().Value("userID").(int64)
		if !ok {
			fmt.Println("No user ID in context")
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusUnauthorized)
			fmt.Fprintf(w, `{"success":false,"message":"Authentication required"}`)
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

		// Find property ID in the path
		var propertyID int64
		for i, part := range cleanParts {
			if part == "property" && i+1 < len(cleanParts) {
				// Next part should be the property ID
				if id, err := strconv.ParseInt(cleanParts[i+1], 10, 64); err == nil {
					propertyID = id
					break
				}
			}
		}

		if propertyID == 0 {
			fmt.Println("No property ID found in URL")
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusBadRequest)
			fmt.Fprintf(w, `{"success":false,"message":"Invalid property ID"}`)
			return
		}

		// Check if user is a manager of this property
		db, err := config.GetDBConnection()
		if err != nil {
			fmt.Printf("Database connection error: %v\n", err)
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintf(w, `{"success":false,"message":"Database connection error"}`)
			return
		}

		var isManager bool
		err = db.QueryRow(`
			SELECT EXISTS(
				SELECT 1 FROM takes_care_of 
				WHERE uid = ? AND pid = ?
			)`, userID, propertyID).Scan(&isManager)
		
		if err != nil {
			fmt.Printf("Error checking manager status: %v\n", err)
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintf(w, `{"success":false,"message":"Error checking authorization"}`)
			return
		}

		if !isManager {
			fmt.Printf("User %d is not a manager of property %d\n", userID, propertyID)
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusForbidden)
			fmt.Fprintf(w, `{"success":false,"message":"Access denied. Manager privileges required."}`)
			return
		}

		fmt.Printf("User %d is authorized as manager of property %d\n", userID, propertyID)
		next.ServeHTTP(w, r)
	})
}

// CORSMiddleware handles Cross-Origin Resource Sharing
func CORSMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Set CORS headers
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, Cookie")
		w.Header().Set("Access-Control-Allow-Credentials", "true")

		// Handle preflight requests
		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

// RateLimitMiddleware implements basic rate limiting
func RateLimitMiddleware(next http.Handler) http.Handler {
	// Simple in-memory rate limiter
	clients := make(map[string]int64)
	
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		clientIP := r.RemoteAddr
		now := time.Now().Unix()
		
		// Clean old entries (older than 1 minute)
		for ip, timestamp := range clients {
			if now-timestamp > 60 {
				delete(clients, ip)
			}
		}
		
		// Check if client has made too many requests
		if lastRequest, exists := clients[clientIP]; exists {
			if now-lastRequest < 1 { // 1 second between requests
				w.Header().Set("Content-Type", "application/json")
				w.WriteHeader(http.StatusTooManyRequests)
				fmt.Fprintf(w, `{"success":false,"message":"Rate limit exceeded. Please wait before making another request."}`)
				return
			}
		}
		
		// Update last request time
		clients[clientIP] = now
		
		next.ServeHTTP(w, r)
	})
} 