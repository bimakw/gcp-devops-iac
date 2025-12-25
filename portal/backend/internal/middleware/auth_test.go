package middleware

import (
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

func TestClaimsStructure(t *testing.T) {
	userID := uuid.New()
	claims := Claims{
		UserID: userID,
		Email:  "test@example.com",
		Role:   "admin",
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	if claims.UserID != userID {
		t.Errorf("expected UserID %v, got %v", userID, claims.UserID)
	}

	if claims.Email != "test@example.com" {
		t.Errorf("expected email test@example.com, got %s", claims.Email)
	}

	if claims.Role != "admin" {
		t.Errorf("expected role admin, got %s", claims.Role)
	}
}

func TestGenerateAndParseJWT(t *testing.T) {
	secret := "test-secret-key"
	userID := uuid.New()

	claims := Claims{
		UserID: userID,
		Email:  "user@test.com",
		Role:   "user",
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(1 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	// Generate token
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(secret))
	if err != nil {
		t.Fatalf("failed to sign token: %v", err)
	}

	// Parse token
	parsedClaims := &Claims{}
	parsedToken, err := jwt.ParseWithClaims(tokenString, parsedClaims, func(token *jwt.Token) (interface{}, error) {
		return []byte(secret), nil
	})

	if err != nil {
		t.Fatalf("failed to parse token: %v", err)
	}

	if !parsedToken.Valid {
		t.Error("token should be valid")
	}

	if parsedClaims.UserID != userID {
		t.Errorf("expected UserID %v, got %v", userID, parsedClaims.UserID)
	}

	if parsedClaims.Email != "user@test.com" {
		t.Errorf("expected email user@test.com, got %s", parsedClaims.Email)
	}

	if parsedClaims.Role != "user" {
		t.Errorf("expected role user, got %s", parsedClaims.Role)
	}
}

func TestJWTWithWrongSecret(t *testing.T) {
	correctSecret := "correct-secret"
	wrongSecret := "wrong-secret"
	userID := uuid.New()

	claims := Claims{
		UserID: userID,
		Email:  "user@test.com",
		Role:   "user",
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(1 * time.Hour)),
		},
	}

	// Generate with correct secret
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, _ := token.SignedString([]byte(correctSecret))

	// Try to parse with wrong secret
	parsedClaims := &Claims{}
	_, err := jwt.ParseWithClaims(tokenString, parsedClaims, func(token *jwt.Token) (interface{}, error) {
		return []byte(wrongSecret), nil
	})

	if err == nil {
		t.Error("should fail with wrong secret")
	}
}

func TestExpiredJWT(t *testing.T) {
	secret := "test-secret"
	userID := uuid.New()

	claims := Claims{
		UserID: userID,
		Email:  "user@test.com",
		Role:   "user",
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(-1 * time.Hour)), // Expired 1 hour ago
			IssuedAt:  jwt.NewNumericDate(time.Now().Add(-2 * time.Hour)),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, _ := token.SignedString([]byte(secret))

	parsedClaims := &Claims{}
	parsedToken, err := jwt.ParseWithClaims(tokenString, parsedClaims, func(token *jwt.Token) (interface{}, error) {
		return []byte(secret), nil
	})

	if err == nil {
		t.Error("should fail with expired token")
	}

	if parsedToken != nil && parsedToken.Valid {
		t.Error("expired token should not be valid")
	}
}

func TestRoleValues(t *testing.T) {
	validRoles := []string{"user", "approver", "admin"}

	for _, role := range validRoles {
		claims := Claims{
			UserID: uuid.New(),
			Email:  "test@test.com",
			Role:   role,
		}

		if claims.Role != role {
			t.Errorf("role should be %s, got %s", role, claims.Role)
		}
	}
}

func TestEmptyClaims(t *testing.T) {
	claims := Claims{}

	if claims.UserID != uuid.Nil {
		t.Error("empty UserID should be uuid.Nil")
	}

	if claims.Email != "" {
		t.Error("empty Email should be empty string")
	}

	if claims.Role != "" {
		t.Error("empty Role should be empty string")
	}
}
