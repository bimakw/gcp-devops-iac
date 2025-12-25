package handlers

import (
	"time"

	"github.com/bimakw/gcp-devops-iac/portal/backend/internal/middleware"
	"github.com/bimakw/gcp-devops-iac/portal/backend/internal/models"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// ApprovalHandler handles approval endpoints
type ApprovalHandler struct {
	db *gorm.DB
}

// NewApprovalHandler creates a new approval handler
func NewApprovalHandler(db *gorm.DB) *ApprovalHandler {
	return &ApprovalHandler{db: db}
}

// ApprovalInput represents input for approve/reject
type ApprovalInput struct {
	Comment string `json:"comment"`
}

// List returns pending approvals
func (h *ApprovalHandler) List(c *fiber.Ctx) error {
	var approvals []models.Approval
	query := h.db.Preload("Request").Preload("Request.Requester").
		Preload("Request.Environment").Preload("Request.ResourceType").
		Preload("Approver")

	// Filter by status
	status := c.Query("status", "pending")
	query = query.Where("approvals.status = ?", status)

	if err := query.Order("created_at DESC").Find(&approvals).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to fetch approvals",
		})
	}

	return c.JSON(approvals)
}

// Get returns a single approval
func (h *ApprovalHandler) Get(c *fiber.Ctx) error {
	id := c.Params("id")

	var approval models.Approval
	if err := h.db.Preload("Request").Preload("Request.Requester").
		Preload("Request.Environment").Preload("Request.ResourceType").
		Preload("Approver").
		First(&approval, "id = ?", id).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Approval not found",
		})
	}

	return c.JSON(approval)
}

// Approve approves a request
func (h *ApprovalHandler) Approve(c *fiber.Ctx) error {
	id := c.Params("id")
	userID := middleware.GetUserID(c)

	var approval models.Approval
	if err := h.db.Preload("Request").First(&approval, "id = ?", id).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Approval not found",
		})
	}

	if approval.Status != "pending" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Approval already processed",
		})
	}

	var input ApprovalInput
	if err := c.BodyParser(&input); err != nil {
		// Comment is optional
	}

	now := time.Now()
	approval.Status = "approved"
	approval.ApproverID = userID
	approval.ApprovedAt = &now
	approval.Comment = input.Comment

	if err := h.db.Save(&approval).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to save approval",
		})
	}

	// Update request status
	approval.Request.Status = models.StatusApproved
	h.db.Save(approval.Request)

	// Create audit log
	h.createAuditLog(c, userID, "approve", "approval", approval.ID)

	h.db.Preload("Request").Preload("Request.Requester").
		Preload("Request.Environment").Preload("Request.ResourceType").
		Preload("Approver").First(&approval, "id = ?", id)

	return c.JSON(approval)
}

// Reject rejects a request
func (h *ApprovalHandler) Reject(c *fiber.Ctx) error {
	id := c.Params("id")
	userID := middleware.GetUserID(c)

	var approval models.Approval
	if err := h.db.Preload("Request").First(&approval, "id = ?", id).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Approval not found",
		})
	}

	if approval.Status != "pending" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Approval already processed",
		})
	}

	var input ApprovalInput
	if err := c.BodyParser(&input); err != nil {
		// Comment is optional but recommended for rejection
	}

	now := time.Now()
	approval.Status = "rejected"
	approval.ApproverID = userID
	approval.ApprovedAt = &now
	approval.Comment = input.Comment

	if err := h.db.Save(&approval).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to save approval",
		})
	}

	// Update request status
	approval.Request.Status = models.StatusRejected
	h.db.Save(approval.Request)

	// Create audit log
	h.createAuditLog(c, userID, "reject", "approval", approval.ID)

	h.db.Preload("Request").Preload("Request.Requester").
		Preload("Request.Environment").Preload("Request.ResourceType").
		Preload("Approver").First(&approval, "id = ?", id)

	return c.JSON(approval)
}

func (h *ApprovalHandler) createAuditLog(c *fiber.Ctx, userID uuid.UUID, action, resourceType string, resourceID uuid.UUID) {
	log := models.AuditLog{
		UserID:       &userID,
		Action:       action,
		ResourceType: resourceType,
		ResourceID:   &resourceID,
		IPAddress:    c.IP(),
		UserAgent:    c.Get("User-Agent"),
	}
	h.db.Create(&log)
}
