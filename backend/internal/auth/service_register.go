package auth

import (
	"context"
	stdErrors "errors"
	"fmt"
	"strings"

	"golang.org/x/crypto/bcrypt"

	"werk-ticketing/internal/errors"
	"werk-ticketing/internal/invgate"
	"werk-ticketing/internal/user"
	"werk-ticketing/internal/validator"
)

func (s *service) Register(ctx context.Context, req RegisterRequest) (*AuthResponse, error) {
	missingFields := validator.ValidateRequiredFields(map[string]string{
		"name":     req.Name,
		"lastname": req.LastName,
		"email":    req.Email,
		"password": req.Password,
	})
	if len(missingFields) > 0 {
		return nil, errors.NewAppError(
			errors.ErrCodeInvalidInput,
			"required fields missing: "+strings.Join(missingFields, ", "),
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

	if !validator.ValidatePassword(req.Password) {
		return nil, errors.NewAppError(
			errors.ErrCodeInvalidInput,
			"password must be at least 6 characters",
			nil,
		)
	}

	existing, err := s.userRepo.GetByEmail(ctx, req.Email)
	if err != nil {
		s.logger.WithError(err).Error("failed to check existing user")
		return nil, errors.NewAppError(
			errors.ErrCodeInternal,
			"failed to check user existence",
			err,
		)
	}
	if existing != nil {
		return nil, errors.NewAppError(
			errors.ErrCodeEmailAlreadyExist,
			"email already registered",
			nil,
		)
	}

	invgateUser, err := s.invgateClient.GetUserByEmail(ctx, req.Email)
	if err == nil && invgateUser != nil {
		s.logger.WithField("email", req.Email).Warn("email already exists in InvGate")
		return nil, errors.NewAppError(
			errors.ErrCodeEmailAlreadyExist,
			"email already in use",
			nil,
		)
	}

	hashed, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		s.logger.WithError(err).Error("failed to hash password")
		return nil, errors.NewAppError(
			errors.ErrCodeInternal,
			"failed to process password",
			err,
		)
	}

	response, err := s.invgateClient.CreateUser(ctx, invgate.CreateUserPayload{
		Name:     req.Name,
		LastName: req.LastName,
		Email:    req.Email,
		Pass:     req.Password,
	})
	if err != nil {
		s.logger.WithError(err).Error("failed to create user in InvGate")
		return nil, errors.NewAppError(
			errors.ErrCodeExternalService,
			"failed to create user in external service",
			err,
		)
	}

	invGateUserID, err := extractInvGateUserID(response)
	if err != nil {
		s.logger.WithError(err).WithField("response", response).Error("failed to extract InvGate user ID")
		return nil, errors.NewAppError(
			errors.ErrCodeExternalService,
			"failed to process external user response",
			err,
		)
	}

	newUser := &user.User{
		Name:          req.Name,
		LastName:      req.LastName,
		Email:         req.Email,
		Password:      string(hashed),
		InvGateUserID: invGateUserID,
		CreatedBy:     req.Email,
		UpdatedBy:     req.Email,
	}

	if err := s.userRepo.Create(ctx, newUser); err != nil {
		var dupKeyErr *user.DuplicateKeyError
		if stdErrors.As(err, &dupKeyErr) {
			if compErr := s.invgateClient.DeleteUser(ctx, invGateUserID); compErr != nil {
				s.logger.WithError(compErr).
					WithField("invGateUserID", invGateUserID).
					WithField("email", req.Email).
					Error("failed to compensate: delete user from InvGate after duplicate key error")
			} else {
				s.logger.WithField("invGateUserID", invGateUserID).
					Info("compensated: deleted user from InvGate after duplicate key error")
			}
			s.logger.WithError(err).Warn("duplicate email detected during registration")
			return nil, errors.NewAppError(
				errors.ErrCodeEmailAlreadyExist,
				"email already registered",
				nil,
			)
		}

		s.logger.WithError(err).
			WithField("invGateUserID", invGateUserID).
			WithField("email", req.Email).
			Error("failed to create user in database, attempting compensation")

		if compErr := s.invgateClient.DeleteUser(ctx, invGateUserID); compErr != nil {
			s.logger.WithError(compErr).
				WithField("invGateUserID", invGateUserID).
				WithField("email", req.Email).
				Error("compensation failed: could not delete user from InvGate - manual cleanup required")
			return nil, errors.NewAppError(
				errors.ErrCodeInternal,
				"failed to create user and compensation failed - manual cleanup may be required",
				fmt.Errorf("create failed: %w, compensation failed: %w", err, compErr),
			)
		}

		s.logger.WithField("invGateUserID", invGateUserID).
			Info("compensated: deleted user from InvGate after local DB creation failure")

		return nil, errors.NewAppError(
			errors.ErrCodeInternal,
			"failed to create user in local database",
			err,
		)
	}

	if err := s.assignUserToDefaultScopes(ctx, invGateUserID); err != nil {
		s.logger.WithError(err).
			WithField("invGateUserID", invGateUserID).
			WithField("email", req.Email).
			Error("failed to assign user to default InvGate scopes, attempting compensation")

		if compErr := s.invgateClient.DeleteUser(ctx, invGateUserID); compErr != nil {
			s.logger.WithError(compErr).
				WithField("invGateUserID", invGateUserID).
				Error("compensation failed: could not delete user from InvGate")
		}

		if compErr := s.userRepo.Delete(ctx, newUser.ID); compErr != nil {
			s.logger.WithError(compErr).
				WithField("userID", newUser.ID).
				Error("compensation failed: could not delete user from local database")
		}

		return nil, errors.NewAppError(
			errors.ErrCodeExternalService,
			"failed to assign user to default configuration",
			err,
		)
	}

	token, err := s.buildToken(newUser)
	if err != nil {
		s.logger.WithError(err).Error("failed to generate token")
		return nil, errors.NewAppError(
			errors.ErrCodeInternal,
			"failed to generate token",
			err,
		)
	}

	refreshToken, err := s.buildRefreshToken(newUser)
	if err != nil {
		s.logger.WithError(err).Error("failed to generate refresh token")
		return nil, errors.NewAppError(
			errors.ErrCodeInternal,
			"failed to generate refresh token",
			err,
		)
	}

	s.logger.Info("user registered successfully")

	return &AuthResponse{
		Token:        token,
		RefreshToken: refreshToken,
		Name:         newUser.Name,
		LastName:     newUser.LastName,
		Email:        newUser.Email,
	}, nil
}

func (s *service) assignUserToDefaultScopes(ctx context.Context, invGateUserID int) error {
	userIDs := []int{invGateUserID}

	if s.companyID > 0 {
		if err := s.invgateClient.AssignUserToCompany(ctx, s.companyID, userIDs); err != nil {
			return fmt.Errorf("assign user to company: %w", err)
		}
	}

	if s.groupID > 0 {
		if err := s.invgateClient.AssignUserToGroup(ctx, s.groupID, userIDs); err != nil {
			return fmt.Errorf("assign user to group: %w", err)
		}
	}

	if s.locationID > 0 {
		if err := s.invgateClient.AssignUserToLocation(ctx, s.locationID, userIDs); err != nil {
			return fmt.Errorf("assign user to location: %w", err)
		}
	}

	return nil
}
