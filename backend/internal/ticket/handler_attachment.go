package ticket

import (
	"fmt"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"

	"werk-ticketing/internal/errors"
	"werk-ticketing/internal/response"
)

// GetAttachment handles GET /api/tickets/attachments/:id
func (h *Handler) GetAttachment(c *gin.Context) {
	attachmentID := c.Param("attachment_id")
	if strings.TrimSpace(attachmentID) == "" {
		response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput, "attachment id is required")
		return
	}

	acceptHeader := c.GetHeader("Accept")
	if strings.Contains(acceptHeader, "application/json") {
		info, err := h.service.GetTicketAttachmentInfo(c.Request.Context(), attachmentID)
		if err != nil {
			if appErr, ok := err.(*errors.AppError); ok {
				response.AppError(c, appErr)
			} else {
				response.ErrorWithCode(c, http.StatusBadGateway, errors.ErrCodeExternalService, err.Error())
			}
			return
		}
		response.Success(c, http.StatusOK, info)
		return
	}

	data, filename, contentType, err := h.service.GetTicketAttachment(c.Request.Context(), attachmentID)
	if err != nil {
		if appErr, ok := err.(*errors.AppError); ok {
			response.AppError(c, appErr)
		} else {
			response.ErrorWithCode(c, http.StatusBadGateway, errors.ErrCodeExternalService, err.Error())
		}
		return
	}

	if contentType == "" {
		contentType = "application/octet-stream"
	}

	if filename != "" {
		c.Header("Content-Disposition", fmt.Sprintf(`attachment; filename="%s"`, filename))
	}
	c.Data(http.StatusOK, contentType, data)
}

