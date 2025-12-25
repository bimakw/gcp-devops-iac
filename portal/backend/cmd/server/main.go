package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/bimakw/gcp-devops-iac/portal/backend/internal/config"
	"github.com/bimakw/gcp-devops-iac/portal/backend/internal/handlers"
	"github.com/bimakw/gcp-devops-iac/portal/backend/internal/middleware"
	"github.com/bimakw/gcp-devops-iac/portal/backend/internal/repository"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
)

func main() {
	// Load configuration
	cfg := config.Load()

	// Connect to database
	db, err := repository.Connect(cfg)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	// Run migrations
	if err := repository.Migrate(db); err != nil {
		log.Fatalf("Failed to run migrations: %v", err)
	}

	// Seed initial data
	if err := repository.Seed(db); err != nil {
		log.Printf("Warning: Failed to seed data: %v", err)
	}

	// Create Fiber app
	app := fiber.New(fiber.Config{
		ErrorHandler: customErrorHandler,
	})

	// Middleware
	app.Use(recover.New())
	app.Use(logger.New(logger.Config{
		Format: "[${time}] ${status} - ${method} ${path} ${latency}\n",
	}))
	app.Use(cors.New(cors.Config{
		AllowOrigins:     cfg.FrontendURL,
		AllowMethods:     "GET,POST,PUT,DELETE,OPTIONS",
		AllowHeaders:     "Origin,Content-Type,Accept,Authorization",
		AllowCredentials: true,
	}))

	// Health check
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "healthy",
			"version": "1.0.0",
		})
	})

	// Initialize handlers
	authHandler := handlers.NewAuthHandler(db, cfg)
	envHandler := handlers.NewEnvironmentHandler(db)
	rtHandler := handlers.NewResourceTypeHandler(db)
	reqHandler := handlers.NewRequestHandler(db)
	approvalHandler := handlers.NewApprovalHandler(db)

	// API routes
	api := app.Group("/api")

	// Auth routes (public)
	auth := api.Group("/auth")
	auth.Get("/google", authHandler.GoogleLogin)
	auth.Get("/google/callback", authHandler.GoogleCallback)

	// Protected routes
	protected := api.Group("", middleware.AuthMiddleware(cfg.JWTSecret))

	// Auth protected
	protected.Get("/auth/me", authHandler.Me)
	protected.Post("/auth/logout", authHandler.Logout)

	// Environments
	protected.Get("/environments", envHandler.List)
	protected.Get("/environments/:id", envHandler.Get)

	// Resource Types
	protected.Get("/resource-types", rtHandler.List)
	protected.Get("/resource-types/:id", rtHandler.Get)
	protected.Get("/resource-types/:id/schema", rtHandler.GetSchema)

	// Requests
	protected.Get("/requests", reqHandler.List)
	protected.Post("/requests", reqHandler.Create)
	protected.Get("/requests/:id", reqHandler.Get)
	protected.Put("/requests/:id", reqHandler.Update)
	protected.Delete("/requests/:id", reqHandler.Delete)
	protected.Post("/requests/:id/submit", reqHandler.Submit)

	// Approvals (approver/admin only)
	approvals := protected.Group("/approvals", middleware.RequireRole("approver", "admin"))
	approvals.Get("/", approvalHandler.List)
	approvals.Get("/:id", approvalHandler.Get)
	approvals.Post("/:id/approve", approvalHandler.Approve)
	approvals.Post("/:id/reject", approvalHandler.Reject)

	// Graceful shutdown
	go func() {
		if err := app.Listen(":" + cfg.Port); err != nil {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	log.Printf("Server started on port %s", cfg.Port)

	// Wait for interrupt signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")
	if err := app.Shutdown(); err != nil {
		log.Fatalf("Server shutdown failed: %v", err)
	}
	log.Println("Server stopped")
}

func customErrorHandler(c *fiber.Ctx, err error) error {
	code := fiber.StatusInternalServerError
	message := "Internal Server Error"

	if e, ok := err.(*fiber.Error); ok {
		code = e.Code
		message = e.Message
	}

	return c.Status(code).JSON(fiber.Map{
		"error": message,
	})
}
