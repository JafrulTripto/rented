package main

import (
	"log"
	"net/http"
	"rented-backend/internal/config"
	"rented-backend/internal/database"
	"rented-backend/internal/handlers"
	"rented-backend/internal/logger"
	"rented-backend/internal/middleware"
	"rented-backend/internal/repository"
	"rented-backend/internal/service"

	"github.com/gin-gonic/gin"
)

func main() {
	// Load Configuration
	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// Initialize Logger
	logger.InitLogger(cfg.Env)
	logger.Log.Info("Starting application", "env", cfg.Env)

	// Initialize database
	database.InitDB(cfg)

	// Initialize S3 Service
	s3Service, err := service.NewS3Service()
	if err != nil {
		log.Printf("Warning: S3 service not initialized: %v. Image uploads will fail.", err)
	}

	rentRepo := repository.NewRentRepository()
	rentHandler := handlers.NewRentHandler(rentRepo)

	houseRepo := repository.NewHouseRepository()
	houseHandler := handlers.NewHouseHandler(houseRepo)

	tenantRepo := repository.NewTenantRepository()
	tenantHandler := handlers.NewTenantHandler(tenantRepo, rentRepo, houseRepo, s3Service)

	userRepo := repository.NewUserRepository()
	authHandler := handlers.NewAuthHandler(userRepo)

	dashboardHandler := handlers.NewDashboardHandler(rentRepo)

	r := gin.Default()

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "up",
		})
	})

	api := r.Group("/api")
	{
		// Auth routes (Public)
		auth := api.Group("/auth")
		{
			auth.POST("/register", authHandler.Register)
			auth.POST("/login", authHandler.Login)
			auth.POST("/google", authHandler.GoogleLogin)
		}

		// Protected routes
		protected := api.Group("/")
		protected.Use(middleware.AuthMiddleware())
		{
			// Auth Profile
			protected.GET("/auth/me", authHandler.GetProfile)

			// Dashboard
			protected.GET("/dashboard", dashboardHandler.GetStats)

			// House & Flat routes
			houses := protected.Group("/houses")
			{
				houses.POST("/", houseHandler.CreateHouse)
				houses.GET("/", houseHandler.GetUserHouses)
				houses.POST("/flats", houseHandler.CreateFlat)
			}

			tenants := protected.Group("/tenants")
			{
				tenants.POST("/", tenantHandler.CreateTenant)
				tenants.GET("/", tenantHandler.GetTenants)
				tenants.GET("/:id", tenantHandler.GetTenant)
				tenants.PUT("/:id", tenantHandler.UpdateTenant)
				tenants.PUT("/:id/status", tenantHandler.UpdateTenantStatus)
				tenants.DELETE("/:id", tenantHandler.DeleteTenant)
				tenants.GET("/:id/rents", rentHandler.GetTenantRents)
			}

			rents := protected.Group("/rents")
			{
				rents.POST("/", rentHandler.CreateRent)
				rents.DELETE("/:id", rentHandler.DeleteRent)
			}
		}
	}

	log.Fatal(r.Run(":8080"))
}
