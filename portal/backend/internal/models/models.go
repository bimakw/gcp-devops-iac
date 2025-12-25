package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// User represents a portal user
type User struct {
	ID        uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Email     string         `gorm:"uniqueIndex;not null" json:"email"`
	Name      string         `gorm:"not null" json:"name"`
	Role      string         `gorm:"default:user" json:"role"` // user, approver, admin
	GoogleID  string         `gorm:"uniqueIndex" json:"-"`
	AvatarURL string         `json:"avatar_url,omitempty"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}

// Environment represents a deployment environment
type Environment struct {
	ID               uuid.UUID `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Name             string    `gorm:"uniqueIndex;not null" json:"name"` // dev, staging, prod
	DisplayName      string    `json:"display_name"`
	Description      string    `json:"description,omitempty"`
	GCPProjectID     string    `json:"gcp_project_id,omitempty"`
	Region           string    `gorm:"default:asia-southeast1" json:"region"`
	RequiresApproval bool      `gorm:"default:false" json:"requires_approval"`
	IsActive         bool      `gorm:"default:true" json:"is_active"`
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt        time.Time `json:"updated_at"`
}

// ResourceType represents a type of infrastructure resource
type ResourceType struct {
	ID           uuid.UUID       `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Name         string          `gorm:"uniqueIndex;not null" json:"name"` // gke, cloudsql, redis
	DisplayName  string          `json:"display_name"`
	Description  string          `json:"description,omitempty"`
	ModulePath   string          `json:"module_path"`
	ConfigSchema JSON            `gorm:"type:jsonb" json:"config_schema"` // JSON Schema
	BaseCost     float64         `gorm:"default:0" json:"base_cost"`
	IsActive     bool            `gorm:"default:true" json:"is_active"`
	CreatedAt    time.Time       `json:"created_at"`
}

// Request represents an infrastructure provisioning request
type Request struct {
	ID             uuid.UUID      `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	Title          string         `gorm:"not null" json:"title"`
	Description    string         `json:"description,omitempty"`
	RequesterID    uuid.UUID      `gorm:"type:uuid;not null" json:"requester_id"`
	Requester      *User          `gorm:"foreignKey:RequesterID" json:"requester,omitempty"`
	EnvironmentID  uuid.UUID      `gorm:"type:uuid;not null" json:"environment_id"`
	Environment    *Environment   `gorm:"foreignKey:EnvironmentID" json:"environment,omitempty"`
	ResourceTypeID uuid.UUID      `gorm:"type:uuid;not null" json:"resource_type_id"`
	ResourceType   *ResourceType  `gorm:"foreignKey:ResourceTypeID" json:"resource_type,omitempty"`
	Configuration  JSON           `gorm:"type:jsonb;not null" json:"configuration"`
	TerraformPlan  string         `json:"terraform_plan,omitempty"`
	EstimatedCost  float64        `json:"estimated_cost"`
	Status         string         `gorm:"default:draft" json:"status"`
	Priority       string         `gorm:"default:normal" json:"priority"`
	CreatedAt      time.Time      `json:"created_at"`
	UpdatedAt      time.Time      `json:"updated_at"`
	SubmittedAt    *time.Time     `json:"submitted_at,omitempty"`
	CompletedAt    *time.Time     `json:"completed_at,omitempty"`
	DeletedAt      gorm.DeletedAt `gorm:"index" json:"-"`
}

// Request statuses
const (
	StatusDraft     = "draft"
	StatusPending   = "pending"
	StatusApproved  = "approved"
	StatusRejected  = "rejected"
	StatusPlanning  = "planning"
	StatusPlanned   = "planned"
	StatusApplying  = "applying"
	StatusApplied   = "applied"
	StatusFailed    = "failed"
	StatusCancelled = "cancelled"
)

// Approval represents an approval decision
type Approval struct {
	ID         uuid.UUID  `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	RequestID  uuid.UUID  `gorm:"type:uuid;not null" json:"request_id"`
	Request    *Request   `gorm:"foreignKey:RequestID" json:"request,omitempty"`
	ApproverID uuid.UUID  `gorm:"type:uuid;not null" json:"approver_id"`
	Approver   *User      `gorm:"foreignKey:ApproverID" json:"approver,omitempty"`
	Status     string     `gorm:"default:pending" json:"status"` // pending, approved, rejected
	Comment    string     `json:"comment,omitempty"`
	ApprovedAt *time.Time `json:"approved_at,omitempty"`
	CreatedAt  time.Time  `json:"created_at"`
}

// AuditLog represents an audit trail entry
type AuditLog struct {
	ID           uuid.UUID  `gorm:"type:uuid;primary_key;default:gen_random_uuid()" json:"id"`
	UserID       *uuid.UUID `gorm:"type:uuid" json:"user_id,omitempty"`
	User         *User      `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Action       string     `gorm:"not null" json:"action"`
	ResourceType string     `json:"resource_type"`
	ResourceID   *uuid.UUID `gorm:"type:uuid" json:"resource_id,omitempty"`
	OldValues    JSON       `gorm:"type:jsonb" json:"old_values,omitempty"`
	NewValues    JSON       `gorm:"type:jsonb" json:"new_values,omitempty"`
	IPAddress    string     `json:"ip_address,omitempty"`
	UserAgent    string     `json:"user_agent,omitempty"`
	CreatedAt    time.Time  `json:"created_at"`
}

// JSON is a custom type for JSONB fields
type JSON map[string]interface{}
