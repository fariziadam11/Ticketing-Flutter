package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
	"werk-ticketing/internal/errors"
	"werk-ticketing/internal/response"
)

// Recover ensures panics are converted to 500 responses with consistent error format.
func Recover(logger *logrus.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if err := recover(); err != nil {
				logger.WithField("panic", err).Error("panic recovered")
				// Use consistent error format
				response.ErrorWithCode(
					c,
					http.StatusInternalServerError,
					errors.ErrCodeInternal,
					"internal server error",
				)
			}
		}()
		c.Next()
	}
}
