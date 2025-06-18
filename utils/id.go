package utils

import (
	"crypto/rand"
	"math/big"
)

// GenerateRandomID generates a random 7-digit number
func GenerateRandomID() (int64, error) {
	max := big.NewInt(8999999)
	n, err := rand.Int(rand.Reader, max)
	if err != nil {
		return 0, err
	}
	return n.Int64() + 1000000, nil
} 