package models

type User struct {
	ID          int    `json:"id"`
	PhoneNumber string `json:"phone_number"`
	Email       string `json:"email,omitempty"`
	NID         string `json:"nid,omitempty"`
	Password    string `json:"password"`
	Manager     *bool  `json:"manager,omitempty"`
	CreatedAt   string `json:"created_at"`
	CreatedBy   int    `json:"created_by"`
	UpdatedAt   string `json:"updated_at"`
	UpdatedBy   int    `json:"updated_by"`
} 