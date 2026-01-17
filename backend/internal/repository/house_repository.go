package repository

import (
	"rented-backend/internal/database"
	"rented-backend/internal/models"

	"github.com/google/uuid"
)

type HouseRepository interface {
	CreateHouse(house *models.House) error
	GetUserHouses(userID uuid.UUID) ([]models.House, error)
	CreateFlat(flat *models.Flat) error
	GetHouseFlats(houseID uuid.UUID) ([]models.Flat, error)
	GetHouseByID(id uuid.UUID) (*models.House, error)
	GetFlatByID(id uuid.UUID) (*models.Flat, error)
}

type houseRepository struct{}

func NewHouseRepository() HouseRepository {
	return &houseRepository{}
}

func (r *houseRepository) CreateHouse(house *models.House) error {
	return database.DB.Create(house).Error
}

func (r *houseRepository) GetUserHouses(userID uuid.UUID) ([]models.House, error) {
	houses := []models.House{}
	err := database.DB.Preload("Flats").Where("user_id = ?", userID).Find(&houses).Error
	return houses, err
}

func (r *houseRepository) CreateFlat(flat *models.Flat) error {
	return database.DB.Create(flat).Error
}

func (r *houseRepository) GetHouseFlats(houseID uuid.UUID) ([]models.Flat, error) {
	flats := []models.Flat{}
	err := database.DB.Where("house_id = ?", houseID).Find(&flats).Error
	return flats, err
}

func (r *houseRepository) GetHouseByID(id uuid.UUID) (*models.House, error) {
	var house models.House
	err := database.DB.First(&house, id).Error
	return &house, err
}

func (r *houseRepository) GetFlatByID(id uuid.UUID) (*models.Flat, error) {
	var flat models.Flat
	err := database.DB.First(&flat, id).Error
	return &flat, err
}
