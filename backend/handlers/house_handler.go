package handlers

import (
	"net/http"
	"rented-backend/logger"
	"rented-backend/models"
	"rented-backend/repository"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type HouseHandler struct {
	repo repository.HouseRepository
}

func NewHouseHandler(repo repository.HouseRepository) *HouseHandler {
	return &HouseHandler{repo: repo}
}

func (h *HouseHandler) CreateHouse(c *gin.Context) {
	var house models.House
	if err := c.ShouldBindJSON(&house); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userIDStr, _ := c.Get("userID")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		logger.Log.Error("Failed to parse userID from context in CreateHouse", "error", err)
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user id"})
		return
	}
	logger.Log.Debug("CreateHouse called", "userID", userID)
	house.UserID = userID
	house.ID = uuid.New()

	if err := h.repo.CreateHouse(&house); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create house"})
		return
	}

	c.JSON(http.StatusCreated, house)
}

func (h *HouseHandler) GetUserHouses(c *gin.Context) {
	userIDStr, _ := c.Get("userID")
	userID, err := uuid.Parse(userIDStr.(string))
	if err != nil {
		logger.Log.Error("Failed to parse userID from context in GetUserHouses", "error", err)
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user id"})
		return
	}
	logger.Log.Debug("GetUserHouses called", "userID", userID)

	houses, err := h.repo.GetUserHouses(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch houses"})
		return
	}

	c.JSON(http.StatusOK, houses)
}

func (h *HouseHandler) CreateFlat(c *gin.Context) {
	var flat models.Flat
	if err := c.ShouldBindJSON(&flat); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	flat.ID = uuid.New()

	if err := h.repo.CreateFlat(&flat); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create flat"})
		return
	}

	c.JSON(http.StatusCreated, flat)
}
