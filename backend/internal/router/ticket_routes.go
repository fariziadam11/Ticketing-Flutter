package router

import (
	"github.com/gin-gonic/gin"

	"werk-ticketing/internal/middleware"
)

// setupTicketRoutes configures ticket routes
// All ticket routes require authentication via JWT token
func (r *Router) setupTicketRoutes(api *gin.RouterGroup) {
	ticketRoutes := api.Group("/tickets")
	ticketRoutes.Use(middleware.WithAuth(r.authService))
	{
		// POST /api/tickets - Create a new ticket
		// Creates a ticket in InvGate Armmada and saves it to local database
		ticketRoutes.POST("", r.ticketHandler.Create)

		// GET /api/tickets - List all tickets
		// Returns paginated list of tickets, filtered by creator_id (optional)
		// Query params: ?creator_id=email&page=1&limit=10
		ticketRoutes.GET("", r.ticketHandler.List)

		// GET /api/tickets/:id - Get ticket detail by ID
		// Returns detailed information about a specific ticket
		// Path param: id (InvGate ticket ID)
		ticketRoutes.GET("/:id", r.ticketHandler.GetByID)

		// PUT /api/tickets/:id - Update an existing ticket
		// Updates ticket fields in InvGate Armmada
		// Path param: id (InvGate ticket ID)
		// Body JSON: { "title"?: string, "description"?: string, "category_id"?: number, ... }
		// All fields are optional - only provided fields will be updated
		ticketRoutes.PUT("/:id", r.ticketHandler.Update)

		// GET /api/tickets/:id/comments - Get comments for a ticket
		ticketRoutes.GET("/:id/comments", r.ticketHandler.GetComments)

		// POST /api/tickets/:id/comments - Add comment to ticket
		ticketRoutes.POST("/:id/comments", r.ticketHandler.AddComment)

		// GET /api/tickets/attachments/:attachment_id - Download attachment file
		ticketRoutes.GET("/attachments/:attachment_id", r.ticketHandler.GetAttachment)

		// PUT /api/tickets/:id/solution - Accept/solve ticket with rating and comment
		// This will call InvGate endpoint: incident.solution.accept
		// Body JSON: { "comment": string, "rating": 1-5 }
		ticketRoutes.PUT("/:id/solution", r.ticketHandler.AcceptSolution)

		// PUT /api/tickets/:id/solution/reject - Reject ticket solution with comment
		// This will call InvGate endpoint: incident.solution.reject
		// Body JSON: { "comment": string }
		ticketRoutes.PUT("/:id/solution/reject", r.ticketHandler.RejectSolution)
	}
}
