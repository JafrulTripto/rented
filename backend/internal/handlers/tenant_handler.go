package handlers

import (
	"fmt"
	"net/http"
	"rented-backend/internal/logger"
	"rented-backend/internal/models"
	"rented-backend/internal/repository"
	"rented-backend/internal/service"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type TenantHandler struct {
	repo      repository.TenantRepository
	rentRepo  repository.RentRepository
	houseRepo repository.HouseRepository
	s3Service *service.S3Service
}

type TenantResponse struct {
	models.Tenant
	DueAmount  float64 `json:"due_amount"`
	TotalPaid  float64 `json:"total_paid"`
	HouseName  string  `json:"house_name"`
	FlatNumber string  `json:"flat_number"`
}

func NewTenantHandler(repo repository.TenantRepository, rentRepo repository.RentRepository, houseRepo repository.HouseRepository, s3Service *service.S3Service) *TenantHandler {
	return &TenantHandler{repo: repo, rentRepo: rentRepo, houseRepo: houseRepo, s3Service: s3Service}
}

func (h *TenantHandler) CreateTenant(c *gin.Context) {
	userIDStr, _ := c.Get("userID")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		logger.Log.Error("Failed to parse userID from context in CreateTenant", "error", err)
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user id"})
		return
	}
	logger.Log.Debug("CreateTenant called", "userID", userID)

	// Using multipart form for images + fields
	name := c.PostForm("name")
	phone := c.PostForm("phone")
	logger.Log.Debug("CreateTenant payload",
		"house_id_raw", c.PostForm("house_id"),
		"flat_id_raw", c.PostForm("flat_id"),
		"name", name,
	)

	houseID, err := uuid.Parse(c.PostForm("house_id"))
	if err != nil {
		logger.Log.Error("Invalid house_id", "error", err, "raw", c.PostForm("house_id"))
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid house_id"})
		return
	}

	flatID, err := uuid.Parse(c.PostForm("flat_id"))
	if err != nil {
		logger.Log.Error("Invalid flat_id", "error", err, "raw", c.PostForm("flat_id"))
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid flat_id"})
		return
	}

	nidNumber := c.PostForm("nid_number")
	advanceAmount, _ := strconv.ParseFloat(c.PostForm("advance_amount"), 64)
	joinDateStr := c.PostForm("join_date")
	joinDate, _ := time.Parse(time.RFC3339, joinDateStr)
	if joinDate.IsZero() {
		joinDate = time.Now()
	}

	tenant := models.Tenant{
		ID:            uuid.New(),
		UserID:        userID,
		HouseID:       houseID,
		FlatID:        flatID,
		Name:          name,
		Phone:         phone,
		NIDNumber:     nidNumber,
		AdvanceAmount: advanceAmount,
		JoinDate:      joinDate,
		IsActive:      true,
	}

	// Handle NID Front Image
	frontFile, err := c.FormFile("nid_front")
	if err == nil {
		url, err := h.s3Service.UploadFile(frontFile, "nids", fmt.Sprintf("%s_front", tenant.ID))
		if err == nil {
			tenant.NIDFrontURL = url
		}
	}

	// Handle NID Back Image
	backFile, err := c.FormFile("nid_back")
	if err == nil {
		url, err := h.s3Service.UploadFile(backFile, "nids", fmt.Sprintf("%s_back", tenant.ID))
		if err == nil {
			tenant.NIDBackURL = url
		}
	}

	if err := h.repo.Create(&tenant); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create tenant"})
		return
	}

	// Create Advance Payment record
	if tenant.AdvanceAmount > 0 {
		advanceRecord := models.RentPayment{
			TenantID:    tenant.ID,
			Month:       "Advance",
			Year:        tenant.JoinDate.Year(),
			TotalPaid:   tenant.AdvanceAmount,
			IsAdvance:   true,
			PaymentDate: time.Now(),
		}
		_ = h.rentRepo.Create(&advanceRecord)
	}

	c.JSON(http.StatusCreated, tenant)
}

func (h *TenantHandler) GetTenants(c *gin.Context) {
	userIDStr, _ := c.Get("userID")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		logger.Log.Error("Failed to parse userID from context", "error", err)
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user id"})
		return
	}
	logger.Log.Debug("GetTenants called", "userID", userID)

	tenants, err := h.repo.GetAll(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	responses := []TenantResponse{}
	for _, t := range tenants {
		rents, _ := h.rentRepo.GetByTenantID(t.ID)
		var totalPaid float64
		for _, r := range rents {
			totalPaid += r.TotalPaid
		}

		// Calculate months since JoinDate
		now := time.Now()
		months := 0
		if !t.JoinDate.IsZero() && t.IsActive {
			years := now.Year() - t.JoinDate.Year()
			months = years*12 + int(now.Month()) - int(t.JoinDate.Month()) + 1
		}

		// Use Flat's BasicRent for calculation
		expectedTotal := float64(months) * t.Flat.BasicRent
		due := expectedTotal - totalPaid
		if due < 0 {
			due = 0
		}

		houseName := "Unknown"
		house, err := h.houseRepo.GetHouseByID(t.HouseID)
		if err == nil {
			houseName = house.Name
		}

		flatNumber := "Unknown"
		flat, err := h.houseRepo.GetFlatByID(t.FlatID)
		if err == nil {
			flatNumber = flat.Number
		}

		responses = append(responses, TenantResponse{
			Tenant:     t,
			DueAmount:  due,
			TotalPaid:  totalPaid,
			HouseName:  houseName,
			FlatNumber: flatNumber,
		})
	}

	c.JSON(http.StatusOK, responses)
}

func (h *TenantHandler) GetTenant(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}

	userIDStr, _ := c.Get("userID")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		logger.Log.Error("Failed to parse userID from context in GetTenant", "error", err)
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user id"})
		return
	}

	tenant, err := h.repo.GetByID(id, userID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "tenant not found"})
		return
	}

	c.JSON(http.StatusOK, tenant)
}

func (h *TenantHandler) UpdateTenantStatus(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}

	userIDStr, _ := c.Get("userID")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		logger.Log.Error("Failed to parse userID from context in UpdateTenantStatus", "error", err)
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user id"})
		return
	}

	var input struct {
		IsActive bool `json:"is_active"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.repo.UpdateStatus(id, userID, input.IsActive); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	tenant, _ := h.repo.GetByID(id, userID)
	c.JSON(http.StatusOK, tenant)
}

func (h *TenantHandler) UpdateTenant(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}

	userIDStr, _ := c.Get("userID")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		logger.Log.Error("Failed to parse userID from context in UpdateTenant", "error", err)
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user id"})
		return
	}

	// In a real app, we might want to allow updating images too
	var tenant models.Tenant
	if err := c.ShouldBindJSON(&tenant); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	tenant.ID = id
	tenant.UserID = userID

	if err := h.repo.Update(&tenant); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, tenant)
}

func (h *TenantHandler) DeleteTenant(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}

	userIDStr, _ := c.Get("userID")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		logger.Log.Error("Failed to parse userID from context in DeleteTenant", "error", err)
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user id"})
		return
	}

	if err := h.repo.Delete(id, userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusNoContent, nil)
}
