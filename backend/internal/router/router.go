package router

import (
	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"

	"werk-ticketing/internal/auth"
	"werk-ticketing/internal/constants"
	"werk-ticketing/internal/middleware"
	"werk-ticketing/internal/ticket"
)

// Router holds all route dependencies
type Router struct {
	authHandler   *auth.Handler
	ticketHandler *ticket.Handler
	authService   auth.Service
	logger        *logrus.Logger
}

// NewRouter creates a new router instance
func NewRouter(
	authHandler *auth.Handler,
	ticketHandler *ticket.Handler,
	authService auth.Service,
	logger *logrus.Logger,
) *Router {
	return &Router{
		authHandler:   authHandler,
		ticketHandler: ticketHandler,
		authService:   authService,
		logger:        logger,
	}
}

// SetupRoutes configures all application routes
func (r *Router) SetupRoutes() *gin.Engine {
	router := gin.New()

	// Global middleware (order matters!)
	router.Use(
		gin.Logger(),
		middleware.Recover(r.logger),
		middleware.CORS(),
		middleware.SecurityHeaders(),
		middleware.RateLimit(),
	)

	// Set max request size
	router.MaxMultipartMemory = constants.MaxRequestSize

	// API versioning: /api/v1
	apiV1 := router.Group("/api/v1")

	// Setup route groups
	r.setupAuthRoutes(apiV1)
	r.setupTicketRoutes(apiV1)

	// User endpoint (proxy to InvGate user API, requires auth)
	userRoutes := apiV1.Group("/users")
	userRoutes.Use(middleware.WithAuth(r.authService))
	{
		// GET /api/users/:id - Get InvGate user detail by ID
		userRoutes.GET("/:id", r.ticketHandler.GetInvGateUser)
	}

	// Categories endpoint (public, no auth required for reference data)
	apiV1.GET("/categories", r.ticketHandler.GetCategories)
	// Ticket meta endpoint (public, no auth required for reference data)
	apiV1.GET("/ticket-meta", r.ticketHandler.GetMeta)
	// Statuses endpoint (public, no auth required for reference data)
	apiV1.GET("/statuses", r.ticketHandler.GetStatuses)
	// Articles endpoint (public, no auth required for reference data)
	apiV1.GET("/articles", r.ticketHandler.GetArticlesByCategory)

	// Health check endpoint (no versioning)
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "ok",
			"service": "werk-ticketing-backend",
		})
	})

	return router
}
