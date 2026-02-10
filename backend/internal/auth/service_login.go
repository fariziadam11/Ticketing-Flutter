package auth

import (
	"context"

	"golang.org/x/crypto/bcrypt"

	"werk-ticketing/internal/errors"
	"werk-ticketing/internal/validator"
)

func (s *service) Login(ctx context.Context, req LoginRequest) (*AuthResponse, error) {
	if !validator.ValidateRequired(req.Email) || !validator.ValidateRequired(req.Password) {
		return nil, errors.NewAppError(
			errors.ErrCodeInvalidInput,
			"email and password are required",
			nil,
		)
	}

	if !validator.ValidateEmail(req.Email) {
		return nil, errors.NewAppError(
			errors.ErrCodeInvalidInput,
			"invalid email format",
			nil,
		)
	}

	existing, err := s.userRepo.GetByEmail(ctx, req.Email)
	if err != nil {
		s.logger.WithError(err).Error("failed to get user")
		return nil, errors.NewAppError(
			errors.ErrCodeInternal,
			"failed to authenticate",
			err,
		)
	}
	if existing == nil {
		s.logger.Warn("login attempt with non-existent email")
		return nil, errors.NewAppError(
			errors.ErrCodeInvalidCredentials,
			"invalid credentials",
			nil,
		)
	}

	if err := bcrypt.CompareHashAndPassword([]byte(existing.Password), []byte(req.Password)); err != nil {
		s.logger.Warn("login attempt with invalid password")
		return nil, errors.NewAppError(
			errors.ErrCodeInvalidCredentials,
			"invalid credentials",
			nil,
		)
	}

	token, err := s.buildToken(existing)
	if err != nil {
		s.logger.WithError(err).Error("failed to generate token")
		return nil, errors.NewAppError(
			errors.ErrCodeInternal,
			"failed to generate token",
			err,
		)
	}

	refreshToken, err := s.buildRefreshToken(existing)
	if err != nil {
		s.logger.WithError(err).Error("failed to generate refresh token")
		return nil, errors.NewAppError(
			errors.ErrCodeInternal,
			"failed to generate refresh token",
			err,
		)
	}

	s.logger.Info("user logged in successfully")

	return &AuthResponse{
		Token:        token,
		RefreshToken: refreshToken,
		Name:         existing.Name,
		LastName:     existing.LastName,
		Email:        existing.Email,
	}, nil
}
