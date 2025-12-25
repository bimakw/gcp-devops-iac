package handlers

import (
	"time"

	"github.com/bimakw/gcp-devops-iac/portal/backend/internal/middleware"
	"github.com/bimakw/gcp-devops-iac/portal/backend/internal/models"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// RequestHandler handles request endpoints
type RequestHandler struct {
	db *gorm.DB
}

// NewRequestHandler creates a new request handler
func NewRequestHandler(db *gorm.DB) *RequestHandler {
	return &RequestHandler{db: db}
}

// CreateRequestInput represents input for creating a request
type CreateRequestInput struct {
	Title          string      `json:"title" validate:"required"`
	Description    string      `json:"description"`
	EnvironmentID  uuid.UUID   `json:"environment_id" validate:"required"`
	ResourceTypeID uuid.UUID   `json:"resource_type_id" validate:"required"`
	Configuration  models.JSON `json:"configuration" validate:"required"`
	Priority       string      `json:"priority"`
}

// List returns all requests
func (h *RequestHandler) List(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)
	role := middleware.GetUserRole(c)

	var requests []models.Request
	query := h.db.Preload("Requester").Preload("Environment").Preload("ResourceType")

	// Non-admins can only see their own requests
	if role != "admin" && role != "approver" {
		query = query.Where("requester_id = ?", userID)
	}

	// Apply filters
	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}
	if envID := c.Query("environment_id"); envID != "" {
		query = query.Where("environment_id = ?", envID)
	}

	if err := query.Order("created_at DESC").Find(&requests).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to fetch requests",
		})
	}

	return c.JSON(requests)
}

// Create creates a new request
func (h *RequestHandler) Create(c *fiber.Ctx) error {
	userID := middleware.GetUserID(c)

	var input CreateRequestInput
	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid input",
		})
	}

	// Verify environment exists
	var env models.Environment
	if err := h.db.First(&env, "id = ?", input.EnvironmentID).Error; err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Environment not found",
		})
	}

	// Verify resource type exists
	var rt models.ResourceType
	if err := h.db.First(&rt, "id = ?", input.ResourceTypeID).Error; err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Resource type not found",
		})
	}

	priority := input.Priority
	if priority == "" {
		priority = "normal"
	}

	request := models.Request{
		Title:          input.Title,
		Description:    input.Description,
		RequesterID:    userID,
		EnvironmentID:  input.EnvironmentID,
		ResourceTypeID: input.ResourceTypeID,
		Configuration:  input.Configuration,
		Status:         models.StatusDraft,
		Priority:       priority,
	}

	if err := h.db.Create(&request).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to create request",
		})
	}

	// Load relations
	h.db.Preload("Requester").Preload("Environment").Preload("ResourceType").First(&request, "id = ?", request.ID)

	return c.Status(fiber.StatusCreated).JSON(request)
}

// Get returns a single request
func (h *RequestHandler) Get(c *fiber.Ctx) error {
	id := c.Params("id")

	var request models.Request
	if err := h.db.Preload("Requester").Preload("Environment").Preload("ResourceType").
		First(&request, "id = ?", id).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Request not found",
		})
	}

	return c.JSON(request)
}

// Update updates a request
func (h *RequestHandler) Update(c *fiber.Ctx) error {
	id := c.Params("id")
	userID := middleware.GetUserID(c)

	var request models.Request
	if err := h.db.First(&request, "id = ?", id).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Request not found",
		})
	}

	// Only requester can update their own draft requests
	if request.RequesterID != userID {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error": "You can only update your own requests",
		})
	}

	if request.Status != models.StatusDraft {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Only draft requests can be updated",
		})
	}

	var input CreateRequestInput
	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid input",
		})
	}

	request.Title = input.Title
	request.Description = input.Description
	request.Configuration = input.Configuration
	if input.Priority != "" {
		request.Priority = input.Priority
	}

	if err := h.db.Save(&request).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to update request",
		})
	}

	h.db.Preload("Requester").Preload("Environment").Preload("ResourceType").First(&request, "id = ?", request.ID)
	return c.JSON(request)
}

// Submit submits a request for approval
func (h *RequestHandler) Submit(c *fiber.Ctx) error {
	id := c.Params("id")
	userID := middleware.GetUserID(c)

	var request models.Request
	if err := h.db.Preload("Environment").First(&request, "id = ?", id).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Request not found",
		})
	}

	if request.RequesterID != userID {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error": "You can only submit your own requests",
		})
	}

	if request.Status != models.StatusDraft && request.Status != models.StatusPlanned {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Request must be in draft or planned status",
		})
	}

	now := time.Now()
	request.SubmittedAt = &now

	// If environment requires approval, set to pending
	if request.Environment.RequiresApproval {
		request.Status = models.StatusPending
	} else {
		request.Status = models.StatusApproved
	}

	if err := h.db.Save(&request).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to submit request",
		})
	}

	h.db.Preload("Requester").Preload("Environment").Preload("ResourceType").First(&request, "id = ?", request.ID)
	return c.JSON(request)
}

// Delete cancels/deletes a request
func (h *RequestHandler) Delete(c *fiber.Ctx) error {
	id := c.Params("id")
	userID := middleware.GetUserID(c)
	role := middleware.GetUserRole(c)

	var request models.Request
	if err := h.db.First(&request, "id = ?", id).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Request not found",
		})
	}

	// Only requester or admin can delete
	if request.RequesterID != userID && role != "admin" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error": "You can only delete your own requests",
		})
	}

	// Can only delete draft or rejected requests
	if request.Status != models.StatusDraft && request.Status != models.StatusRejected {
		request.Status = models.StatusCancelled
		h.db.Save(&request)
		return c.JSON(fiber.Map{"message": "Request cancelled"})
	}

	if err := h.db.Delete(&request).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to delete request",
		})
	}

	return c.JSON(fiber.Map{"message": "Request deleted"})
}
