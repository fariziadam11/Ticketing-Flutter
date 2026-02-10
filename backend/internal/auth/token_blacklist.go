package auth

import (
	"context"
	"sync"
	"time"
)

// TokenBlacklist manages blacklisted tokens in memory
// In production, consider using Redis or database for distributed systems
type TokenBlacklist struct {
	tokens map[string]time.Time
	mu     sync.RWMutex
}

// NewTokenBlacklist creates a new token blacklist
func NewTokenBlacklist() *TokenBlacklist {
	tb := &TokenBlacklist{
		tokens: make(map[string]time.Time),
	}

	// Cleanup expired tokens periodically
	go tb.cleanup()

	return tb
}

// Add adds a token to the blacklist with expiration time
func (tb *TokenBlacklist) Add(token string, expiresAt time.Time) {
	tb.mu.Lock()
	defer tb.mu.Unlock()
	tb.tokens[token] = expiresAt
}

// IsBlacklisted checks if a token is blacklisted
func (tb *TokenBlacklist) IsBlacklisted(token string) bool {
	tb.mu.RLock()
	defer tb.mu.RUnlock()
	
	expiresAt, exists := tb.tokens[token]
	if !exists {
		return false
	}
	
	// If token has expired, remove it and return false
	if time.Now().After(expiresAt) {
		tb.mu.RUnlock()
		tb.mu.Lock()
		delete(tb.tokens, token)
		tb.mu.Unlock()
		tb.mu.RLock()
		return false
	}
	
	return true
}

// cleanup removes expired tokens periodically
func (tb *TokenBlacklist) cleanup() {
	ticker := time.NewTicker(1 * time.Hour)
	defer ticker.Stop()

	for range ticker.C {
		tb.mu.Lock()
		now := time.Now()
		for token, expiresAt := range tb.tokens {
			if now.After(expiresAt) {
				delete(tb.tokens, token)
			}
		}
		tb.mu.Unlock()
	}
}

// TokenBlacklistService interface for token blacklist operations
type TokenBlacklistService interface {
	AddToken(ctx context.Context, token string, expiresAt time.Time) error
	IsTokenBlacklisted(ctx context.Context, token string) (bool, error)
	RevokeToken(ctx context.Context, token string) error
}

