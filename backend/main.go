package main

import (
	"log"
	"rented-backend/config"
	"rented-backend/database"
	"rented-backend/handlers"
	"rented-backend/logger"
	"rented-backend/repository"
	"rented-backend/router"
	"rented-backend/service"
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

	r := router.SetupRouter(
		authHandler,
		houseHandler,
		tenantHandler,
		rentHandler,
		dashboardHandler,
	)

	log.Fatal(r.Run(":8080"))
}
