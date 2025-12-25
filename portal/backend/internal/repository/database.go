package repository

import (
	"log"

	"github.com/bimakw/gcp-devops-iac/portal/backend/internal/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// Database wraps the GORM DB instance
type Database struct {
	*gorm.DB
}

// NewDatabase creates a new database connection
func NewDatabase(dsn string) (*Database, error) {
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		return nil, err
	}

	return &Database{db}, nil
}

// Connect creates a database connection from config
func Connect(cfg interface{ GetDSN() string }) (*gorm.DB, error) {
	db, err := gorm.Open(postgres.Open(cfg.GetDSN()), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		return nil, err
	}
	return db, nil
}

// Migrate runs database migrations
func Migrate(db *gorm.DB) error {
	log.Println("Running database migrations...")

	err := db.AutoMigrate(
		&models.User{},
		&models.Environment{},
		&models.ResourceType{},
		&models.Request{},
		&models.Approval{},
		&models.AuditLog{},
	)
	if err != nil {
		return err
	}

	log.Println("Migrations completed successfully")
	return nil
}

// Seed seeds initial data
func Seed(db *gorm.DB) error {
	d := &Database{db}
	d.seedEnvironments()
	d.seedResourceTypes()
	return nil
}

// Migrate runs database migrations
func (d *Database) Migrate() error {
	log.Println("Running database migrations...")

	err := d.AutoMigrate(
		&models.User{},
		&models.Environment{},
		&models.ResourceType{},
		&models.Request{},
		&models.Approval{},
		&models.AuditLog{},
	)
	if err != nil {
		return err
	}

	// Seed default environments if not exist
	d.seedEnvironments()

	// Seed default resource types if not exist
	d.seedResourceTypes()

	log.Println("Migrations completed successfully")
	return nil
}

func (d *Database) seedEnvironments() {
	environments := []models.Environment{
		{
			Name:             "dev",
			DisplayName:      "Development",
			Description:      "Development environment for testing",
			RequiresApproval: false,
			IsActive:         true,
		},
		{
			Name:             "staging",
			DisplayName:      "Staging",
			Description:      "Staging environment for pre-production testing",
			RequiresApproval: true,
			IsActive:         true,
		},
		{
			Name:             "prod",
			DisplayName:      "Production",
			Description:      "Production environment",
			RequiresApproval: true,
			IsActive:         true,
		},
	}

	for _, env := range environments {
		d.FirstOrCreate(&env, models.Environment{Name: env.Name})
	}
}

func (d *Database) seedResourceTypes() {
	resourceTypes := []models.ResourceType{
		{
			Name:        "gke",
			DisplayName: "GKE Cluster",
			Description: "Google Kubernetes Engine cluster",
			ModulePath:  "terraform/modules/gke",
			ConfigSchema: models.JSON{
				"type": "object",
				"properties": map[string]interface{}{
					"machine_type": map[string]interface{}{
						"type":    "string",
						"title":   "Machine Type",
						"enum":    []string{"e2-standard-2", "e2-standard-4", "e2-standard-8"},
						"default": "e2-standard-2",
					},
					"min_nodes": map[string]interface{}{
						"type":    "integer",
						"title":   "Minimum Nodes",
						"minimum": 1,
						"maximum": 10,
						"default": 1,
					},
					"max_nodes": map[string]interface{}{
						"type":    "integer",
						"title":   "Maximum Nodes",
						"minimum": 1,
						"maximum": 50,
						"default": 5,
					},
					"create_spot_pool": map[string]interface{}{
						"type":    "boolean",
						"title":   "Create Spot Node Pool",
						"default": false,
					},
				},
				"required": []string{"machine_type", "min_nodes", "max_nodes"},
			},
			IsActive: true,
		},
		{
			Name:        "cloudsql",
			DisplayName: "Cloud SQL",
			Description: "Managed PostgreSQL database",
			ModulePath:  "terraform/modules/cloudsql",
			ConfigSchema: models.JSON{
				"type": "object",
				"properties": map[string]interface{}{
					"tier": map[string]interface{}{
						"type":    "string",
						"title":   "Instance Tier",
						"enum":    []string{"db-f1-micro", "db-g1-small", "db-custom-2-4096", "db-custom-4-8192"},
						"default": "db-f1-micro",
					},
					"disk_size_gb": map[string]interface{}{
						"type":    "integer",
						"title":   "Disk Size (GB)",
						"minimum": 10,
						"maximum": 500,
						"default": 10,
					},
					"high_availability": map[string]interface{}{
						"type":    "boolean",
						"title":   "High Availability",
						"default": false,
					},
				},
				"required": []string{"tier", "disk_size_gb"},
			},
			IsActive: true,
		},
		{
			Name:        "redis",
			DisplayName: "Memorystore Redis",
			Description: "Managed Redis cache",
			ModulePath:  "terraform/modules/memorystore",
			ConfigSchema: models.JSON{
				"type": "object",
				"properties": map[string]interface{}{
					"memory_size_gb": map[string]interface{}{
						"type":    "integer",
						"title":   "Memory Size (GB)",
						"minimum": 1,
						"maximum": 16,
						"default": 1,
					},
					"tier": map[string]interface{}{
						"type":    "string",
						"title":   "Tier",
						"enum":    []string{"BASIC", "STANDARD_HA"},
						"default": "BASIC",
					},
				},
				"required": []string{"memory_size_gb", "tier"},
			},
			IsActive: true,
		},
	}

	for _, rt := range resourceTypes {
		d.FirstOrCreate(&rt, models.ResourceType{Name: rt.Name})
	}
}
