package constants

import "time"

// JWT token expiration
const (
	JWTExpiration      = 15 * time.Minute // 15 minutes
	JWTRefreshExpiration = 8760 * time.Hour // 1 year (365 days * 24 hours)
)

// HTTP timeout
const (
	HTTPClientTimeoutSeconds = 15
)

// Database connection pool
const (
	DBMaxOpenConns    = 25
	DBMaxIdleConns    = 25
	DBConnMaxLifetime = 5 // minutes
	DBConnMaxIdleTime = 5 // minutes
)

// Server configuration
const (
	GracefulShutdownTimeout = 30 * time.Second
	MaxRequestSize          = 10 << 20 // 10 MB
)

// Rate limiting
const (
	RateLimitRequestsPerMinute = 100 // Increased to 100 requests per minute
	RateLimitBurst             = 30  // Increased burst to handle multiple parallel requests
)

// Retry configuration for external API calls
const (
	RetryMaxAttempts        = 3
	RetryInitialDelayMs     = 500  // 500ms
	RetryMaxDelayMs         = 5000 // 5 seconds
	RetryBackoffMultiplier  = 2.0
)

