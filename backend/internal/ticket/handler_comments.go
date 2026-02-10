package ticket

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"

	"werk-ticketing/internal/errors"
	"werk-ticketing/internal/middleware"
	"werk-ticketing/internal/response"
)

// AddComment handles POST /api/tickets/:id/comments
func (h *Handler) AddComment(c *gin.Context) {
	ticketIDParam := c.Param("id")
	if ticketIDParam == "" {
		response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput, "ticket id is required")
		return
	}

	requestID, convErr := strconv.Atoi(ticketIDParam)
	if convErr != nil {
		response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput, "ticket id must be numeric")
		return
	}

	var (
		req TicketCommentRequest
		err error
	)
	if strings.Contains(c.GetHeader("Content-Type"), "multipart/form-data") {
		req, err = bindCommentMultipart(c)
		if err != nil {
			response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput, err.Error())
			return
		}
	} else {
		if err := c.ShouldBindJSON(&req); err != nil {
			response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput, "invalid JSON body")
			return
		}
	}

	req.RequestID = requestID

	if strings.TrimSpace(req.Comment) == "" {
		response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput, "comment is required")
		return
	}

	authorEmail := middleware.GetUserEmail(c)
	if authorEmail == "" {
		response.ErrorWithCode(c, http.StatusUnauthorized, errors.ErrCodeUnauthorized, "user email not found")
		return
	}

	resp, err := h.service.AddTicketComment(c.Request.Context(), req, authorEmail)
	if err != nil {
		if appErr, ok := err.(*errors.AppError); ok {
			response.AppError(c, appErr)
		} else {
			response.ErrorWithCode(c, http.StatusBadGateway, errors.ErrCodeExternalService, err.Error())
		}
		return
	}

	response.Write(c, http.StatusCreated, resp)
}

// GetComments handles GET /api/tickets/:id/comments
func (h *Handler) GetComments(c *gin.Context) {
	ticketIDParam := c.Param("id")
	if ticketIDParam == "" {
		response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput, "ticket id is required")
		return
	}

	requestID, err := strconv.Atoi(ticketIDParam)
	if err != nil {
		response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput, "ticket id must be numeric")
		return
	}

	resp, err := h.service.GetTicketComments(c.Request.Context(), requestID)
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

