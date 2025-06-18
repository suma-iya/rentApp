package utils

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"
)

// GenerateCSRFToken generates a random CSRF token
func GenerateCSRFToken() (string, error) {
	// Generate 32 random bytes
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", fmt.Errorf("error generating CSRF token: %v", err)
	}
	
	// Encode to base64
	return base64.StdEncoding.EncodeToString(b), nil
}

// ValidateCSRFToken validates if the provided token matches the expected token
func ValidateCSRFToken(providedToken, expectedToken string) bool {
	return providedToken == expectedToken
} 