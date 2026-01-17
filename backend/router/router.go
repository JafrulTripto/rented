package router

import (
	"net/http"
	"rented-backend/handlers"
	"rented-backend/middleware"

	"github.com/gin-gonic/gin"
)

func SetupRouter(
	authHandler *handlers.AuthHandler,
	houseHandler *handlers.HouseHandler,
	tenantHandler *handlers.TenantHandler,
	rentHandler *handlers.RentHandler,
	dashboardHandler *handlers.DashboardHandler,
) *gin.Engine {
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

	return r
}
