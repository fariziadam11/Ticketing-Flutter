package auth

import (
	"context"
	"time"

	"github.com/golang-jwt/jwt/v5"

	"werk-ticketing/internal/constants"
	"werk-ticketing/internal/errors"
	"werk-ticketing/internal/user"
)

func (s *service) ParseToken(token string) (*jwt.RegisteredClaims, error) {
	if s.IsTokenBlacklisted(token) {
		return nil, errors.NewAppError(
			errors.ErrCodeUnauthorized,
			"token has been revoked",
			nil,
		)
	}

	parsed, err := jwt.ParseWithClaims(token, &jwt.RegisteredClaims{}, func(t *jwt.Token) (interface{}, error) {
		return s.jwtSecret, nil
	})
	if err != nil {
		return nil, errors.NewAppError(
			errors.ErrCodeUnauthorized,
			"invalid token",
			err,
		)
	}

	claims, ok := parsed.Claims.(*jwt.RegisteredClaims)
	if !ok || !parsed.Valid {
		return nil, errors.NewAppError(
			errors.ErrCodeUnauthorized,
			"invalid token",
			nil,
		)
	}
	return claims, nil
}

func (s *service) RefreshToken(ctx context.Context, refreshToken string) (*AuthResponse, error) {
	claims, err := s.ParseToken(refreshToken)
	if err != nil {
		return nil, err
	}

	user, err := s.userRepo.GetByEmail(ctx, claims.Subject)
	if err != nil {
		s.logger.WithError(err).Error("failed to get user for token refresh")
		return nil, errors.NewAppError(
			errors.ErrCodeInternal,
			"failed to refresh token",
			err,
		)
	}
	if user == nil {
		return nil, errors.NewAppError(
			errors.ErrCodeUnauthorized,
			"user not found",
			nil,
		)
	}

	token, err := s.buildToken(user)
	if err != nil {
		s.logger.WithError(err).Error("failed to generate refresh token")
		return nil, errors.NewAppError(
			errors.ErrCodeInternal,
			"failed to generate token",
			err,
		)
	}

	refreshTokenNew, err := s.buildRefreshToken(user)
	if err != nil {
		s.logger.WithError(err).Error("failed to generate refresh token")
		return nil, errors.NewAppError(
			errors.ErrCodeInternal,
			"failed to generate refresh token",
			err,
		)
	}

	s.logger.Info("token refreshed successfully")

	return &AuthResponse{
		Token:        token,
		RefreshToken: refreshTokenNew,
		Name:         user.Name,
		LastName:     user.LastName,
		Email:        user.Email,
	}, nil
}

func (s *service) RevokeToken(ctx context.Context, token string) error {
	claims, err := s.ParseToken(token)
	if err != nil {
		s.blacklist.Add(token, time.Now().Add(constants.JWTExpiration))
		return nil
	}

	if claims.ExpiresAt != nil {
		s.blacklist.Add(token, claims.ExpiresAt.Time)
	} else {
		s.blacklist.Add(token, time.Now().Add(constants.JWTExpiration))
	}

	s.logger.Info("token revoked")
	return nil
}

func (s *service) IsTokenBlacklisted(token string) bool {
	return s.blacklist.IsBlacklisted(token)
}

func (s *service) buildToken(u *user.User) (string, error) {
	claims := jwt.RegisteredClaims{
		Subject:   u.Email,
		IssuedAt:  jwt.NewNumericDate(time.Now().UTC()),
		ExpiresAt: jwt.NewNumericDate(time.Now().UTC().Add(constants.JWTExpiration)),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(s.jwtSecret)
}

func (s *service) buildRefreshToken(u *user.User) (string, error) {
	claims := jwt.RegisteredClaims{
		Subject:   u.Email,
		IssuedAt:  jwt.NewNumericDate(time.Now().UTC()),
		ExpiresAt: jwt.NewNumericDate(time.Now().UTC().Add(constants.JWTRefreshExpiration)),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(s.jwtSecret)
}
