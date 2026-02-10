package response

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"werk-ticketing/internal/errors"
)

// Success writes a successful JSON response
func Success(c *gin.Context, status int, data interface{}) {
	c.JSON(status, gin.H{
		"success": true,
		"data":    data,
	})
}

// Write writes JSON response with status code (legacy, for backward compatibility)
// Note: This function doesn't enforce consistent response format.
// Consider using Success() for new code to maintain consistency.
func Write(c *gin.Context, status int, payload interface{}) {
	c.JSON(status, payload)
}

// Error writes error payload in unified format
func Error(c *gin.Context, status int, message string) {
	c.AbortWithStatusJSON(status, gin.H{
		"success": false,
		"error":   message,
	})
}

// ErrorWithCode writes error payload with error code
func ErrorWithCode(c *gin.Context, status int, code, message string) {
	c.AbortWithStatusJSON(status, gin.H{
		"success": false,
		"error":   message,
		"code":    code,
	})
}

// AppError writes application error response
func AppError(c *gin.Context, appErr *errors.AppError) {
	status := http.StatusInternalServerError
	code := appErr.Code

	switch code {
	case errors.ErrCodeInvalidInput:
		status = http.StatusBadRequest
	case errors.ErrCodeNotFound:
		status = http.StatusNotFound
	case errors.ErrCodeUnauthorized:
		status = http.StatusUnauthorized
	case errors.ErrCodeForbidden:
		status = http.StatusForbidden
	case errors.ErrCodeInvalidCredentials:
		// Invalid credentials should return 401 Unauthorized (not 500)
		status = http.StatusUnauthorized
	case errors.ErrCodeEmailAlreadyExist:
		// Email already exists should return 409 Conflict (not 500)
		status = http.StatusConflict
	case errors.ErrCodeExternalService:
		status = http.StatusBadGateway
	default:
		status = http.StatusInternalServerError
	}

	ErrorWithCode(c, status, code, appErr.Message)
}
