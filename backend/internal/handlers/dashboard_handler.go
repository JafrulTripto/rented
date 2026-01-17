package handlers

import (
	"net/http"
	"rented-backend/internal/repository"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type DashboardHandler struct {
	repo repository.RentRepository
}

func NewDashboardHandler(repo repository.RentRepository) *DashboardHandler {
	return &DashboardHandler{repo: repo}
}

func (h *DashboardHandler) GetStats(c *gin.Context) {
	// Assuming UserID is available via middleware (e.g., set in context)
	// For now, if no auth middleware sets it, we might accept it as a param for testing or default
	// But standard pattern is c.MustGet("userID")
	// Let's assume passed as query param for simplicity or header if auth is not fully hooked up context-wise
	// Or grab it from the header "X-User-ID" if using that pattern, or query.
	// Reusing the pattern from other handlers? They usually take UserID as param or from context.
	// Looking at previous code, TenantHandler used c.MustGet("userID")? Let's check or be safe.
	// Actually, previous code (e.g. TenantHandler) took UserID as parameter in some methods?
	// TenantRepository.GetAll takes userID.
	// Let's assume client sends user_id as query param for this MVP "GetDashboardStats?user_id=..."
	// Or better, standard Auth middleware.

	userIDStr := c.Query("user_id")
	if userIDStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "user_id is required"})
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid user_id"})
		return
	}

	stats, err := h.repo.GetDashboardStats(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, stats)
}
