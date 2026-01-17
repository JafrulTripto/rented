package config

import (
	"fmt"
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	AppPort    string
	DBHost     string
	DBUser     string
	DBPassword string
	DBName     string
	DBPort     string
	JWTSecret  string
	Env        string
}

func LoadConfig() (*Config, error) {
	// Load .env file if it exists (for local development)
	_ = godotenv.Load()

	config := &Config{
		AppPort:    getEnv("APP_PORT", "8080"),
		DBHost:     getEnv("DB_HOST", "localhost"),
		DBUser:     getEnv("DB_USER", "postgres"),
		DBPassword: getEnv("DB_PASSWORD", "password"),
		DBName:     getEnv("DB_NAME", "rented"),
		DBPort:     getEnv("DB_PORT", "5432"),
		JWTSecret:  getEnv("JWT_SECRET", "default_secret_change_me_in_prod"),
		Env:        getEnv("ENV", "development"),
	}

	if config.DBHost == "" || config.DBUser == "" {
		return nil, fmt.Errorf("missing required environment variables")
	}

	return config, nil
}

func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return fallback
}
