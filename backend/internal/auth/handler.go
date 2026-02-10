package auth

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"

	"werk-ticketing/internal/errors"
	"werk-ticketing/internal/response"
)

// Handler exposes HTTP handlers for auth routes.
type Handler struct {
	service Service
}

// NewHandler wires auth service into http handler.
func NewHandler(service Service) *Handler {
	return &Handler{service: service}
}

// Register handles POST /auth/register
func (h *Handler) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput, "invalid JSON body")
		return
	}

	resp, err := h.service.Register(c.Request.Context(), req)
	if err != nil {
		if appErr, ok := err.(*errors.AppError); ok {
			response.AppError(c, appErr)
		} else {
			response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput, err.Error())
		}
		return
	}

	response.Write(c, http.StatusCreated, resp)
}

// Login handles POST /auth/login
func (h *Handler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput, "invalid JSON body")
		return
	}

	resp, err := h.service.Login(c.Request.Context(), req)
	if err != nil {
		if appErr, ok := err.(*errors.AppError); ok {
			response.AppError(c, appErr)
		} else {
			response.ErrorWithCode(c, http.StatusUnauthorized, errors.ErrCodeUnauthorized, err.Error())
		}
		return
	}

	response.Write(c, http.StatusOK, resp)
}

// RefreshToken handles POST /auth/refresh
func (h *Handler) RefreshToken(c *gin.Context) {
	var req RefreshTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput, "invalid JSON body")
		return
	}

	resp, err := h.service.RefreshToken(c.Request.Context(), req.RefreshToken)
	if err != nil {
		if appErr, ok := err.(*errors.AppError); ok {
			response.AppError(c, appErr)
		} else {
			response.ErrorWithCode(c, http.StatusUnauthorized, errors.ErrCodeUnauthorized, err.Error())
		}
		return
	}

	response.Write(c, http.StatusOK, resp)
}

// RevokeToken handles POST /auth/revoke
func (h *Handler) RevokeToken(c *gin.Context) {
	// Get token from Authorization header
	header := c.GetHeader("Authorization")
	if header == "" {
		response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput, "missing authorization header")
		return
	}

	parts := strings.SplitN(header, " ", 2)
	if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
		response.ErrorWithCode(c, http.StatusBadRequest, errors.ErrCodeInvalidInput, "invalid authorization format")
		return
	}

	token := parts[1]
	if err := h.service.RevokeToken(c.Request.Context(), token); err != nil {
		if appErr, ok := err.(*errors.AppError); ok {
			response.AppError(c, appErr)
		} else {
			response.ErrorWithCode(c, http.StatusInternalServerError, errors.ErrCodeInternal, err.Error())
		}
		return
	}

	response.Write(c, http.StatusOK, gin.H{"message": "token revoked successfully"})
}
