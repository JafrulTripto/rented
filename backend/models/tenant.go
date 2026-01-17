package models

import (
	"time"

	"github.com/google/uuid"
)

type Tenant struct {
	ID            uuid.UUID `json:"id" gorm:"type:uuid;primary_key;"`
	UserID        uuid.UUID `json:"user_id" gorm:"type:uuid"`
	HouseID       uuid.UUID `json:"house_id" gorm:"type:uuid"`
	FlatID        uuid.UUID `json:"flat_id" gorm:"type:uuid"`
	Flat          Flat      `json:"flat" gorm:"foreignKey:FlatID"`
	Name          string    `json:"name" binding:"required"`
	Phone         string    `json:"phone" binding:"required"`
	NIDNumber     string    `json:"nid_number"`
	NIDFrontURL   string    `json:"nid_front_url"`
	NIDBackURL    string    `json:"nid_back_url"`
	IsActive      bool      `json:"is_active" gorm:"default:true"`
	JoinDate      time.Time `json:"join_date"`
	AdvanceAmount float64   `json:"advance_amount"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}
