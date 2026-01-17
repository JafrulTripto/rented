package repository

import (
	"rented-backend/database"
	"rented-backend/models"

	"github.com/google/uuid"
)

type UserRepository interface {
	Create(user *models.User) error
	GetByEmail(email string) (*models.User, error)
	GetByID(id uuid.UUID) (*models.User, error)
	GetByGoogleID(googleID string) (*models.User, error)
}

type userRepository struct{}

func NewUserRepository() UserRepository {
	return &userRepository{}
}

func (r *userRepository) Create(user *models.User) error {
	user.ID = uuid.New()
	return database.DB.Create(user).Error
}

func (r *userRepository) GetByEmail(email string) (*models.User, error) {
	var user models.User
	err := database.DB.Where("email = ?", email).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) GetByID(id uuid.UUID) (*models.User, error) {
	var user models.User
	err := database.DB.First(&user, "id = ?", id).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) GetByGoogleID(googleID string) (*models.User, error) {
	var user models.User
	err := database.DB.Where("google_id = ?", googleID).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}
