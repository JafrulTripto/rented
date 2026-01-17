package handlers

import (
	"net/http"
	"rented-backend/models"
	"rented-backend/repository"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type RentHandler struct {
	repo repository.RentRepository
}

func NewRentHandler(repo repository.RentRepository) *RentHandler {
	return &RentHandler{repo: repo}
}

func (h *RentHandler) CreateRent(c *gin.Context) {
	var rent models.RentPayment
	if err := c.ShouldBindJSON(&rent); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.repo.Create(&rent); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, rent)
}

func (h *RentHandler) GetTenantRents(c *gin.Context) {
	tenantID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid tenant_id"})
		return
	}

	rents, err := h.repo.GetByTenantID(tenantID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, rents)
}

func (h *RentHandler) DeleteRent(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}

	if err := h.repo.Delete(id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusNoContent, nil)
}
