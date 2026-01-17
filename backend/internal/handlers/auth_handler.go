package handlers

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"rented-backend/internal/models"
	"rented-backend/internal/repository"
	"time"

	"cloud.google.com/go/auth/credentials/idtoken"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type AuthHandler struct {
	userRepo repository.UserRepository
}

func NewAuthHandler(userRepo repository.UserRepository) *AuthHandler {
	return &AuthHandler{userRepo: userRepo}
}

func (h *AuthHandler) Register(c *gin.Context) {
	var req models.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to hash password"})
		return
	}

	user := models.User{
		Email:    req.Email,
		Password: string(hashedPassword),
		Name:     req.Name,
	}

	if err := h.userRepo.Create(&user); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create user"})
		return
	}

	token, err := h.generateToken(user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate token"})
		return
	}

	c.JSON(http.StatusCreated, models.AuthResponse{User: user, Token: token})
}

func (h *AuthHandler) GoogleLogin(c *gin.Context) {
	var req models.GoogleLoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	clientID := os.Getenv("GOOGLE_CLIENT_ID")
	payload, err := idtoken.Validate(c.Request.Context(), req.IDToken, clientID)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid google token"})
		return
	}

	googleID := payload.Subject
	email := fmt.Sprintf("%v", payload.Claims["email"])
	name := fmt.Sprintf("%v", payload.Claims["name"])

	// 1. Try to find by GoogleID
	user, err := h.userRepo.GetByGoogleID(googleID)
	if err != nil {
		// 2. Try to find by Email (linking accounts)
		user, err = h.userRepo.GetByEmail(email)
		if err == nil {
			// Link the account
			user.GoogleID = googleID
			// In a real app, update repository here
		} else {
			// 3. Create new user
			user = &models.User{
				Email:    email,
				Name:     name,
				GoogleID: googleID,
			}
			if err := h.userRepo.Create(user); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create user"})
				return
			}
		}
	}

	token, err := h.generateToken(*user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate token"})
		return
	}

	c.JSON(http.StatusOK, models.AuthResponse{User: *user, Token: token})
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, err := h.userRepo.GetByEmail(req.Email)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid credentials"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid credentials"})
		return
	}

	token, err := h.generateToken(*user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate token"})
		return
	}

	c.JSON(http.StatusOK, models.AuthResponse{User: *user, Token: token})
}

func (h *AuthHandler) generateToken(user models.User) (string, error) {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"sub":   user.ID.String(),
		"email": user.Email,
		"exp":   time.Now().Add(time.Hour * 72).Unix(),
	})

	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		jwtSecret = "default_secret" // fallback for development
		log.Println("WARNING: JWT_SECRET not set, using default")
	}

	return token.SignedString([]byte(jwtSecret))
}

func (h *AuthHandler) GetProfile(c *gin.Context) {
	// AuthMiddleware sets "userID"
	userIDStr, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	userID, err := uuid.Parse(fmt.Sprintf("%v", userIDStr))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid user id"})
		return
	}

	user, err := h.userRepo.GetByID(userID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}

	c.JSON(http.StatusOK, user)
}
