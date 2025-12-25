package handlers

import (
	"github.com/bimakw/gcp-devops-iac/portal/backend/internal/models"
	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

// ResourceTypeHandler handles resource type endpoints
type ResourceTypeHandler struct {
	db *gorm.DB
}

// NewResourceTypeHandler creates a new resource type handler
func NewResourceTypeHandler(db *gorm.DB) *ResourceTypeHandler {
	return &ResourceTypeHandler{db: db}
}

// List returns all resource types
func (h *ResourceTypeHandler) List(c *fiber.Ctx) error {
	var resourceTypes []models.ResourceType
	if err := h.db.Where("is_active = ?", true).Find(&resourceTypes).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to fetch resource types",
		})
	}
	return c.JSON(resourceTypes)
}

// Get returns a single resource type
func (h *ResourceTypeHandler) Get(c *fiber.Ctx) error {
	id := c.Params("id")

	var resourceType models.ResourceType
	if err := h.db.First(&resourceType, "id = ? OR name = ?", id, id).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Resource type not found",
		})
	}

	return c.JSON(resourceType)
}

// GetSchema returns the configuration schema for a resource type
func (h *ResourceTypeHandler) GetSchema(c *fiber.Ctx) error {
	id := c.Params("id")

	var resourceType models.ResourceType
	if err := h.db.First(&resourceType, "id = ? OR name = ?", id, id).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Resource type not found",
		})
	}

	return c.JSON(resourceType.ConfigSchema)
}
