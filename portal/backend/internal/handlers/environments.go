package handlers

import (
	"github.com/bimakw/gcp-devops-iac/portal/backend/internal/models"
	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

// EnvironmentHandler handles environment endpoints
type EnvironmentHandler struct {
	db *gorm.DB
}

// NewEnvironmentHandler creates a new environment handler
func NewEnvironmentHandler(db *gorm.DB) *EnvironmentHandler {
	return &EnvironmentHandler{db: db}
}

// List returns all environments
func (h *EnvironmentHandler) List(c *fiber.Ctx) error {
	var environments []models.Environment
	if err := h.db.Where("is_active = ?", true).Find(&environments).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to fetch environments",
		})
	}
	return c.JSON(environments)
}

// Get returns a single environment
func (h *EnvironmentHandler) Get(c *fiber.Ctx) error {
	id := c.Params("id")

	var environment models.Environment
	if err := h.db.First(&environment, "id = ? OR name = ?", id, id).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Environment not found",
		})
	}

	return c.JSON(environment)
}
