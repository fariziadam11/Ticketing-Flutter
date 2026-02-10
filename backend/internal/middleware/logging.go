package middleware

import (
	"fmt"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

// Logging logs incoming HTTP requests with latency.
func Logging(logger *logrus.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		c.Next()
		duration := time.Since(start)
		status := c.Writer.Status()
		coloredStatus := fmt.Sprintf("%s%d%s", statusColor(status), status, colorReset)
		coloredMethod := fmt.Sprintf("%s%-7s%s", methodColor(c.Request.Method), c.Request.Method, colorReset)

		logger.Infof("%s %s %s (%s)",
			coloredStatus,
			coloredMethod,
			c.Request.URL.Path,
			duration.String(),
		)
	}
}

const (
	colorReset   = "\033[0m"
	colorRed     = "\033[31m"
	colorGreen   = "\033[32m"
	colorYellow  = "\033[33m"
	colorCyan    = "\033[36m"
	colorMagenta = "\033[35m"
)

func statusColor(status int) string {
	switch {
	case status >= 500:
		return colorRed
	case status >= 400:
		return colorYellow
	case status >= 300:
		return colorCyan
	default:
		return colorGreen
	}
}

func methodColor(method string) string {
	switch method {
	case "GET":
		return colorCyan
	case "POST":
		return colorGreen
	case "PUT":
		return colorYellow
	case "DELETE":
		return colorRed
	default:
		return colorMagenta
	}
}
