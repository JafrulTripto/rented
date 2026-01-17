package repository

import (
	"rented-backend/internal/database"
	"rented-backend/internal/models"

	"github.com/google/uuid"
)

type TenantRepository interface {
	Create(tenant *models.Tenant) error
	GetAll(userID uuid.UUID) ([]models.Tenant, error)
	GetByID(id uuid.UUID, userID uuid.UUID) (*models.Tenant, error)
	Update(tenant *models.Tenant) error
	UpdateStatus(id uuid.UUID, userID uuid.UUID, isActive bool) error
	Delete(id uuid.UUID, userID uuid.UUID) error
}

type tenantRepository struct{}

func NewTenantRepository() TenantRepository {
	return &tenantRepository{}
}

func (r *tenantRepository) Create(tenant *models.Tenant) error {
	return database.DB.Create(tenant).Error
}

func (r *tenantRepository) GetAll(userID uuid.UUID) ([]models.Tenant, error) {
	var tenants []models.Tenant
	err := database.DB.Preload("Flat").Where("user_id = ?", userID).Find(&tenants).Error
	return tenants, err
}

func (r *tenantRepository) GetByID(id uuid.UUID, userID uuid.UUID) (*models.Tenant, error) {
	var tenant models.Tenant
	err := database.DB.Preload("Flat").Where("id = ? AND user_id = ?", id, userID).First(&tenant).Error
	if err != nil {
		return nil, err
	}
	return &tenant, nil
}

func (r *tenantRepository) Update(tenant *models.Tenant) error {
	return database.DB.Save(tenant).Error
}

func (r *tenantRepository) UpdateStatus(id uuid.UUID, userID uuid.UUID, isActive bool) error {
	return database.DB.Model(&models.Tenant{}).Where("id = ? AND user_id = ?", id, userID).Update("is_active", isActive).Error
}

func (r *tenantRepository) Delete(id uuid.UUID, userID uuid.UUID) error {
	return database.DB.Where("id = ? AND user_id = ?", id, userID).Delete(&models.Tenant{}).Error
}
