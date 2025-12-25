package config

import (
	"os"
)

// Config holds all configuration for the application
type Config struct {
	// Server
	Port string
	Env  string

	// Database
	DatabaseURL string

	// Google OAuth
	GoogleClientID     string
	GoogleClientSecret string
	GoogleRedirectURL  string

	// JWT
	JWTSecret string

	// GCP
	GCPProjectID         string
	GCPRegion            string
	TerraformStateBucket string

	// Frontend
	FrontendURL string
}

// Load loads configuration from environment variables
func Load() *Config {
	return &Config{
		Port:                 getEnv("PORT", "8080"),
		Env:                  getEnv("ENV", "development"),
		DatabaseURL:          getEnv("DATABASE_URL", "postgres://postgres:postgres@localhost:5432/infra_portal?sslmode=disable"),
		GoogleClientID:       getEnv("GOOGLE_CLIENT_ID", ""),
		GoogleClientSecret:   getEnv("GOOGLE_CLIENT_SECRET", ""),
		GoogleRedirectURL:    getEnv("GOOGLE_REDIRECT_URL", "http://localhost:8080/api/auth/google/callback"),
		JWTSecret:            getEnv("JWT_SECRET", "your-secret-key-change-in-production"),
		GCPProjectID:         getEnv("GCP_PROJECT_ID", ""),
		GCPRegion:            getEnv("GCP_REGION", "asia-southeast1"),
		TerraformStateBucket: getEnv("TERRAFORM_STATE_BUCKET", ""),
		FrontendURL:          getEnv("FRONTEND_URL", "http://localhost:3000"),
	}
}

func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return fallback
}

// GetDSN returns the database connection string
func (c *Config) GetDSN() string {
	return c.DatabaseURL
}
