package middleware

import (
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"werk-ticketing/internal/constants"
	"werk-ticketing/internal/response"
)

// RateLimiter implements a simple in-memory rate limiter
type RateLimiter struct {
	visitors map[string]*visitor
	mu       sync.RWMutex
	rate     int           // requests per minute
	burst    int           // burst size
	ttl      time.Duration // time to live for visitor records
}

type visitor struct {
	lastSeen time.Time
	count    int
	mu       sync.Mutex
}

// NewRateLimiter creates a new rate limiter
func NewRateLimiter(rate, burst int) *RateLimiter {
	rl := &RateLimiter{
		visitors: make(map[string]*visitor),
		rate:     rate,
		burst:    burst,
		ttl:      time.Minute,
	}

	// Cleanup old visitors periodically
	go rl.cleanup()

	return rl
}

func (rl *RateLimiter) cleanup() {
	for {
		time.Sleep(time.Minute)
		rl.mu.Lock()
		for ip, v := range rl.visitors {
			v.mu.Lock()
			if time.Since(v.lastSeen) > rl.ttl {
				delete(rl.visitors, ip)
			}
			v.mu.Unlock()
		}
		rl.mu.Unlock()
	}
}

func (rl *RateLimiter) allow(ip string) bool {
	rl.mu.Lock()
	v, exists := rl.visitors[ip]
	if !exists {
		v = &visitor{
			lastSeen: time.Now(),
			count:    1,
		}
		rl.visitors[ip] = v
		rl.mu.Unlock()
		return true
	}
	rl.mu.Unlock()

	v.mu.Lock()
	defer v.mu.Unlock()

	// Reset count if a minute has passed
	if time.Since(v.lastSeen) > time.Minute {
		v.count = 1
		v.lastSeen = time.Now()
		return true
	}

	// Check if within rate limit
	if v.count >= rl.rate {
		return false
	}

	v.count++
	v.lastSeen = time.Now()
	return true
}

var globalRateLimiter = NewRateLimiter(constants.RateLimitRequestsPerMinute, constants.RateLimitBurst)

// RateLimit returns a middleware that rate limits requests
func RateLimit() gin.HandlerFunc {
	return func(c *gin.Context) {
		ip := c.ClientIP()
		
		if !globalRateLimiter.allow(ip) {
			response.Error(c, 429, "too many requests")
			c.Abort()
			return
		}

		c.Next()
	}
}

