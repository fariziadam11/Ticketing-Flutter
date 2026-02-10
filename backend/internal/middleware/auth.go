package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"

	"werk-ticketing/internal/auth"
	"werk-ticketing/internal/errors"
	"werk-ticketing/internal/response"
)

const userEmailKey = "userEmail"

// WithAuth ensures the request has a valid JWT token.
func WithAuth(authService auth.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		if header == "" {
			response.ErrorWithCode(c, http.StatusUnauthorized, errors.ErrCodeUnauthorized, "missing authorization header")
			return
		}

		parts := strings.SplitN(header, " ", 2)
		if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
			response.ErrorWithCode(c, http.StatusUnauthorized, errors.ErrCodeUnauthorized, "invalid authorization format")
			return
		}

		claims, err := authService.ParseToken(parts[1])
		if err != nil {
			if appErr, ok := err.(*errors.AppError); ok {
				response.AppError(c, appErr)
			} else {
				response.ErrorWithCode(c, http.StatusUnauthorized, errors.ErrCodeUnauthorized, "invalid token")
			}
			return
		}

		c.Set(userEmailKey, claims.Subject)
		c.Next()
	}
}

// GetUserEmail extracts the authenticated user email from the request context.
func GetUserEmail(c *gin.Context) string {
	if email, ok := c.Get(userEmailKey); ok {
		if s, ok := email.(string); ok {
			return s
		}
	}
	return ""
}
