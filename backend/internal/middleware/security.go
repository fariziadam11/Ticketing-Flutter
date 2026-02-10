package middleware

import (
	"github.com/gin-gonic/gin"
)

// SecurityHeaders adds security headers to responses
func SecurityHeaders() gin.HandlerFunc {
	return func(c *gin.Context) {
		// HSTS - HTTP Strict Transport Security
		c.Header("Strict-Transport-Security", "max-age=31536000; includeSubDomains; preload")
		
		// X-Frame-Options - Prevent clickjacking
		c.Header("X-Frame-Options", "DENY")
		
		// X-Content-Type-Options - Prevent MIME type sniffing
		c.Header("X-Content-Type-Options", "nosniff")
		
		// X-XSS-Protection - Enable XSS filtering
		c.Header("X-XSS-Protection", "1; mode=block")
		
		// Referrer-Policy - Control referrer information
		c.Header("Referrer-Policy", "strict-origin-when-cross-origin")
		
		// Content-Security-Policy - Prevent XSS attacks
		// Adjust this based on your needs
		csp := "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self'"
		c.Header("Content-Security-Policy", csp)
		
		// Permissions-Policy - Control browser features
		c.Header("Permissions-Policy", "geolocation=(), microphone=(), camera=()")

		c.Next()
	}
}

