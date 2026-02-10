package ticket

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"

	"werk-ticketing/internal/errors"
	"werk-ticketing/internal/middleware"
	"werk-ticketing/internal/response"
)

// List handles GET /api/tickets
func (h *Handler) List(c *gin.Context) {
	creatorID := c.Query("creator_id")
	if creatorID == "" {
		creatorID = middleware.GetUserEmail(c)
	}

	page := 1
	if pageStr := c.Query("page"); pageStr != "" {
		if parsed, err := strconv.Atoi(pageStr); err == nil && parsed > 0 {
			page = parsed
		}
	}

	limit := 10
	if limitStr := c.Query("limit"); limitStr != "" {
		if parsed, err := strconv.Atoi(limitStr); err == nil && parsed > 0 {
			limit = parsed
		}
	}

	resp, err := h.service.GetTickets(c.Request.Context(), creatorID, page, limit)
	if err != nil {
		if appErr, ok := err.(*errors.AppError); ok {
			response.AppError(c, appErr)
		} else {
			response.ErrorWithCode(c, http.StatusBadGateway, errors.ErrCodeExternalService, err.Error())
		}
		return
	}

	response.Write(c, http.StatusOK, resp)
}

// GetByID handles GET /api/tickets/:id
func (h *Handler) GetByID(c *gin.Context) {
	ticketID := c.Param("id")
	if ticketID == "" {
		response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput, "ticket id is required")
		return
	}

	resp, err := h.service.GetTicketDetail(c.Request.Context(), ticketID)
	if err != nil {
		if appErr, ok := err.(*errors.AppError); ok {
			response.AppError(c, appErr)
		} else {
			response.ErrorWithCode(c, http.StatusBadGateway, errors.ErrCodeExternalService, err.Error())
		}
		return
	}

	response.Write(c, http.StatusOK, resp)
}

// GetStatuses handles GET /api/statuses
func (h *Handler) GetStatuses(c *gin.Context) {
	resp, err := h.service.GetStatuses(c.Request.Context())
	if err != nil {
		if appErr, ok := err.(*errors.AppError); ok {
			response.AppError(c, appErr)
		} else {
			response.ErrorWithCode(c, http.StatusInternalServerError, errors.ErrCodeInternal, err.Error())
		}
		return
	}

	response.Write(c, http.StatusOK, resp)
}

// GetCategories handles GET /api/categories
func (h *Handler) GetCategories(c *gin.Context) {
	resp, err := h.service.GetCategories(c.Request.Context())
	if err != nil {
		if appErr, ok := err.(*errors.AppError); ok {
			response.AppError(c, appErr)
		} else {
			response.ErrorWithCode(c, http.StatusBadGateway, errors.ErrCodeExternalService, err.Error())
		}
		return
	}

	response.Write(c, http.StatusOK, resp)
}

// GetMeta handles GET /api/ticket-meta
func (h *Handler) GetMeta(c *gin.Context) {
	resp, err := h.service.GetTicketMeta(c.Request.Context())
	if err != nil {
		if appErr, ok := err.(*errors.AppError); ok {
			response.AppError(c, appErr)
		} else {
			response.ErrorWithCode(c, http.StatusInternalServerError, errors.ErrCodeInternal, err.Error())
		}
		return
	}

	response.Write(c, http.StatusOK, resp)
}

// GetArticlesByCategory handles GET /api/articles
func (h *Handler) GetArticlesByCategory(c *gin.Context) {
	categoryIDParam := c.Query("category_id")
	if categoryIDParam == "" {
		response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput, "category_id query parameter is required")
		return
	}

	categoryID, err := strconv.Atoi(categoryIDParam)
	if err != nil {
		response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput, "category_id must be a valid integer")
		return
	}

	resp, err := h.service.GetArticlesByCategory(c.Request.Context(), categoryID)
	if err != nil {
		if appErr, ok := err.(*errors.AppError); ok {
			response.AppError(c, appErr)
		} else {
			response.ErrorWithCode(c, http.StatusBadGateway, errors.ErrCodeExternalService, err.Error())
		}
		return
	}

	response.Write(c, http.StatusOK, resp)
}

// GetInvGateUser handles GET /api/users/:id
func (h *Handler) GetInvGateUser(c *gin.Context) {
	idParam := c.Param("id")
	if idParam == "" {
		response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput, "user id is required")
		return
	}

	userID, err := strconv.Atoi(idParam)
	if err != nil {
		response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput, "user id must be numeric")
		return
	}

	resp, err := h.service.GetInvGateUser(c.Request.Context(), userID)
	if err != nil {
		if appErr, ok := err.(*errors.AppError); ok {
			response.AppError(c, appErr)
		} else {
			response.ErrorWithCode(c, http.StatusBadGateway, errors.ErrCodeExternalService, err.Error())
		}
		return
	}

	response.Write(c, http.StatusOK, resp)
}

// Update handles PUT /api/tickets/:id
func (h *Handler) Update(c *gin.Context) {
	ticketIDParam := c.Param("id")
	if ticketIDParam == "" {
		response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput, "ticket id is required")
		return
	}

	ticketID, err := strconv.Atoi(ticketIDParam)
	if err != nil {
		response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput, "ticket id must be numeric")
		return
	}

	var req TicketUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput, "invalid JSON body")
		return
	}

	if req.DateOcurred != nil && *req.DateOcurred > 0 {
		now := time.Now().Unix()
		if int64(*req.DateOcurred) > now {
			response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput,
				"date_ocurred cannot be in the future")
			return
		}
	}

	resp, err := h.service.UpdateTicket(c.Request.Context(), ticketID, req)
	if err != nil {
		if appErr, ok := err.(*errors.AppError); ok {
			response.AppError(c, appErr)
		} else {
			response.ErrorWithCode(c, http.StatusBadGateway, errors.ErrCodeExternalService, err.Error())
		}
		return
	}

	response.Write(c, http.StatusOK, resp)
}

