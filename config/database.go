package config

import (
	"database/sql"
	"fmt"
	_ "github.com/go-sql-driver/mysql"
	"time"
)

const (
	DBUser     = "suma"      // Change this to your MySQL username
	DBPassword = "tMyc6mApj]wgzHl7"          // Change this to your MySQL password
	DBHost     = "localhost" // Change this if your MySQL is on a different host
	DBPort     = "3307"      // Default MySQL port
	DBName     = "rent"      // Your database name
)

var db *sql.DB

// InitDB initializes the database connection
func InitDB() error {
	var err error
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?parseTime=true", DBUser, DBPassword, DBHost, DBPort, DBName)
	
	db, err = sql.Open("mysql", dsn)
	if err != nil {
		return fmt.Errorf("error opening database: %v", err)
	}

	// Test the connection
	err = db.Ping()
	if err != nil {
		return fmt.Errorf("error connecting to the database: %v", err)
	}

	// Set connection pool settings
	db.SetMaxOpenConns(50)                // Increased from 25
	db.SetMaxIdleConns(25)               // Keep idle connections
	db.SetConnMaxLifetime(time.Hour)     // Maximum lifetime of a connection
	db.SetConnMaxIdleTime(30 * time.Minute) // Maximum idle time of a connection

	return nil
}

// GetDBConnection returns the database connection
func GetDBConnection() (*sql.DB, error) {
	if db == nil {
		return nil, fmt.Errorf("database not initialized")
	}
	
	// Verify the connection is still alive
	if err := db.Ping(); err != nil {
		// Try to reinitialize the connection
		if err := InitDB(); err != nil {
			return nil, fmt.Errorf("database connection lost and failed to reconnect: %v", err)
		}
	}
	
	return db, nil
} 