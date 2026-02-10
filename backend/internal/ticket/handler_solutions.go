package ticket

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"

	"werk-ticketing/internal/errors"
	"werk-ticketing/internal/response"
)

// AcceptSolution handles PUT /api/tickets/:id/solution
func (h *Handler) AcceptSolution(c *gin.Context) {
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

	var body struct {
		Comment string `json:"comment"`
		Rating  int    `json:"rating"`
	}

	if err := c.ShouldBindJSON(&body); err != nil {
		response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput, "invalid JSON body")
		return
	}

	if strings.TrimSpace(body.Comment) == "" {
		response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput, "comment is required")
		return
	}

	if body.Rating < 1 || body.Rating > 5 {
		response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput, "rating must be between 1 and 5")
		return
	}

	req := TicketSolutionRequest{
		RequestID: requestID,
		Rating:    body.Rating,
		Comment:   body.Comment,
	}

	resp, err := h.service.UpdateTicketSolution(c.Request.Context(), req)
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

// RejectSolution handles PUT /api/tickets/:id/solution/reject
func (h *Handler) RejectSolution(c *gin.Context) {
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

	var body struct {
		Comment string `json:"comment"`
	}

	if err := c.ShouldBindJSON(&body); err != nil {
		response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput, "invalid JSON body")
		return
	}

	if strings.TrimSpace(body.Comment) == "" {
		response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput, "comment is required")
		return
	}

	req := TicketSolutionRejectRequest{
		RequestID: requestID,
		Comment:   body.Comment,
	}

	resp, err := h.service.RejectTicketSolution(c.Request.Context(), req)
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

