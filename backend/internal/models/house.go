package models

import (
	"time"

	"github.com/google/uuid"
)

type House struct {
	ID        uuid.UUID `json:"id" gorm:"type:uuid;primary_key;"`
	UserID    uuid.UUID `json:"user_id" gorm:"type:uuid;not null"`
	Name      string    `json:"name" binding:"required"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
	Flats     []Flat    `json:"flats" gorm:"foreignKey:HouseID"`
}

type Flat struct {
	ID           uuid.UUID `json:"id" gorm:"type:uuid;primary_key;"`
	HouseID      uuid.UUID `json:"house_id" gorm:"type:uuid;not null"`
	Number       string    `json:"number" binding:"required"`
	BasicRent    float64   `json:"basic_rent"`
	GasBill      float64   `json:"gas_bill"`
	UtilityBill  float64   `json:"utility_bill"`
	WaterCharges float64   `json:"water_charges"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}
