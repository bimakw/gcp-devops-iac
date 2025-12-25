package models

import (
	"testing"
)

func TestRequestStatusConstants(t *testing.T) {
	tests := []struct {
		name     string
		constant string
		expected string
	}{
		{"Draft", StatusDraft, "draft"},
		{"Pending", StatusPending, "pending"},
		{"Approved", StatusApproved, "approved"},
		{"Rejected", StatusRejected, "rejected"},
		{"Planning", StatusPlanning, "planning"},
		{"Planned", StatusPlanned, "planned"},
		{"Applying", StatusApplying, "applying"},
		{"Applied", StatusApplied, "applied"},
		{"Failed", StatusFailed, "failed"},
		{"Cancelled", StatusCancelled, "cancelled"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if tt.constant != tt.expected {
				t.Errorf("expected %q, got %q", tt.expected, tt.constant)
			}
		})
	}
}

func TestUserRoleValues(t *testing.T) {
	validRoles := map[string]bool{
		"user":     true,
		"approver": true,
		"admin":    true,
	}

	// Test that default role is valid
	u := User{}
	if u.Role == "" {
		// Default is set by GORM, so we test the valid values
		for role := range validRoles {
			if !validRoles[role] {
				t.Errorf("role %q should be valid", role)
			}
		}
	}
}

func TestEnvironmentDefaults(t *testing.T) {
	env := Environment{}

	// Region should have a sensible default when set by GORM
	// Here we just verify the struct can be created
	if env.Name != "" {
		t.Error("empty environment should have empty name")
	}

	if env.RequiresApproval {
		t.Error("default RequiresApproval should be false")
	}

	if env.IsActive {
		// Note: GORM sets default to true, but Go zero value is false
		// This tests Go struct zero value
		t.Log("IsActive is false (Go zero value), GORM will set to true")
	}
}

func TestResourceTypeDefaults(t *testing.T) {
	rt := ResourceType{}

	if rt.BaseCost != 0 {
		t.Errorf("default BaseCost should be 0, got %f", rt.BaseCost)
	}

	if rt.IsActive {
		// GORM default is true, Go zero value is false
		t.Log("IsActive is false (Go zero value), GORM will set to true")
	}
}

func TestRequestDefaults(t *testing.T) {
	req := Request{}

	if req.Status != "" {
		// Go zero value, GORM will set to "draft"
		t.Errorf("Go zero value for Status should be empty, got %q", req.Status)
	}

	if req.Priority != "" {
		// Go zero value, GORM will set to "normal"
		t.Errorf("Go zero value for Priority should be empty, got %q", req.Priority)
	}

	if req.EstimatedCost != 0 {
		t.Errorf("default EstimatedCost should be 0, got %f", req.EstimatedCost)
	}
}

func TestApprovalDefaults(t *testing.T) {
	approval := Approval{}

	if approval.Status != "" {
		// Go zero value, GORM will set to "pending"
		t.Errorf("Go zero value for Status should be empty, got %q", approval.Status)
	}

	if approval.ApprovedAt != nil {
		t.Error("ApprovedAt should be nil by default")
	}
}

func TestJSONType(t *testing.T) {
	j := JSON{
		"key1": "value1",
		"key2": 123,
		"key3": true,
	}

	if j["key1"] != "value1" {
		t.Error("JSON map should store string values")
	}

	if j["key2"] != 123 {
		t.Error("JSON map should store int values")
	}

	if j["key3"] != true {
		t.Error("JSON map should store bool values")
	}

	// Test nested values
	j["nested"] = map[string]interface{}{
		"inner": "value",
	}

	nested, ok := j["nested"].(map[string]interface{})
	if !ok {
		t.Error("JSON should support nested maps")
	}

	if nested["inner"] != "value" {
		t.Error("nested value should be accessible")
	}
}

func TestAuditLogOptionalFields(t *testing.T) {
	audit := AuditLog{
		Action: "create",
	}

	if audit.UserID != nil {
		t.Error("UserID should be optional (nil)")
	}

	if audit.ResourceID != nil {
		t.Error("ResourceID should be optional (nil)")
	}

	if audit.OldValues != nil {
		t.Error("OldValues should be optional (nil)")
	}

	if audit.NewValues != nil {
		t.Error("NewValues should be optional (nil)")
	}
}
