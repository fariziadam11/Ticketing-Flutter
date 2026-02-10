package ticket

import (
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"

	"werk-ticketing/internal/errors"
	"werk-ticketing/internal/middleware"
	"werk-ticketing/internal/response"
	"werk-ticketing/internal/validator"
)

// Create handles POST /api/tickets
func (h *Handler) Create(c *gin.Context) {
	var (
		req TicketRequest
		err error
	)

	if strings.Contains(c.GetHeader("Content-Type"), "multipart/form-data") {
		req, err = bindTicketMultipart(c)
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

	missingFields := validator.ValidateRequiredFields(map[string]string{
		"title":       req.Title,
		"description": req.Description,
	})
	if len(missingFields) > 0 {
		response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput,
			"required fields missing: "+strings.Join(missingFields, ", "))
		return
	}

	if req.DateOcurred > 0 {
		now := time.Now().Unix()
		if int64(req.DateOcurred) > now {
			response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput,
				"date_ocurred cannot be in the future")
			return
		}
	}

	creatorEmail := middleware.GetUserEmail(c)
	if creatorEmail == "" {
		response.ErrorWithCode(c, http.StatusUnauthorized, errors.ErrCodeUnauthorized, "user email not found")
		return
	}

	resp, err := h.service.CreateTicket(c.Request.Context(), req, creatorEmail)
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

