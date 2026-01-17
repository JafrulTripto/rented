package models

import (
	"time"

	"github.com/google/uuid"
)

type RentPayment struct {
	ID              uuid.UUID `json:"id" gorm:"type:uuid;primary_key;"`
	TenantID        uuid.UUID `json:"tenant_id" gorm:"type:uuid;index"`
	Month           string    `json:"month" binding:"required"` // e.g., "January"
	Year            int       `json:"year" binding:"required"`
	BasicRent       float64   `json:"basic_rent"`
	GasBill         float64   `json:"gas_bill"`
	ElectricityBill float64   `json:"electricity_bill"`
	UtilityBill     float64   `json:"utility_bill"`
	WaterCharges    float64   `json:"water_charges"`
	TotalPaid       float64   `json:"total_paid"`
	IsAdvance       bool      `json:"is_advance" gorm:"default:false"`
	PaymentDate     time.Time `json:"payment_date"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}
