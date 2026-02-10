package errors

import (
	"errors"
	"fmt"
)

// Error codes
const (
	ErrCodeInvalidInput       = "INVALID_INPUT"
	ErrCodeNotFound           = "NOT_FOUND"
	ErrCodeUnauthorized       = "UNAUTHORIZED"
	ErrCodeForbidden          = "FORBIDDEN"
	ErrCodeInternal           = "INTERNAL_ERROR"
	ErrCodeExternalService    = "EXTERNAL_SERVICE_ERROR"
	ErrCodeEmailAlreadyExist  = "EMAIL_ALREADY_EXIST"
	ErrCodeInvalidCredentials = "INVALID_CREDENTIALS"
)

// Predefined errors
var (
	ErrInvalidInput      = errors.New("invalid input")
	ErrNotFound          = errors.New("resource not found")
	ErrUnauthorized      = errors.New("unauthorized")
	ErrForbidden         = errors.New("forbidden")
	ErrInternal          = errors.New("internal server error")
	ErrExternalService   = errors.New("external service error")
	ErrEmailAlreadyExist = errors.New("email already registered")
	ErrInvalidCredentials = errors.New("invalid credentials")
)

// AppError represents an application error with context
type AppError struct {
	Code    string
	Message string
	Err     error
}

func (e *AppError) Error() string {
	if e.Err != nil {
		return fmt.Sprintf("%s: %v", e.Message, e.Err)
	}
	return e.Message
}

func (e *AppError) Unwrap() error {
	return e.Err
}

// NewAppError creates a new application error
func NewAppError(code, message string, err error) *AppError {
	return &AppError{
		Code:    code,
		Message: message,
		Err:     err,
	}
}

// WrapError wraps an error with context
func WrapError(message string, err error) error {
	if err == nil {
		return nil
	}
	return fmt.Errorf("%s: %w", message, err)
}

