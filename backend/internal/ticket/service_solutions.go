package ticket

import (
	"context"
	"strings"

	"github.com/sirupsen/logrus"

	"werk-ticketing/internal/errors"
	"werk-ticketing/internal/invgate"
)

func (s *service) UpdateTicketSolution(ctx context.Context, req TicketSolutionRequest) (map[string]interface{}, error) {
	if req.RequestID <= 0 {
		return nil, errors.NewAppError(
			errors.ErrCodeInvalidInput,
			"request_id must be a positive integer",
			nil,
		)
	}

	if req.Rating < 1 || req.Rating > 5 {
		return nil, errors.NewAppError(
			errors.ErrCodeInvalidInput,
			"rating must be between 1 and 5",
			nil,
		)
	}

	if strings.TrimSpace(req.Comment) == "" {
		return nil, errors.NewAppError(
			errors.ErrCodeInvalidInput,
			"comment is required",
			nil,
		)
	}

	resp, err := s.client.SolutionAccept(ctx, invgate.SolutionAcceptPayload{
		ID:      req.RequestID,
		Comment: req.Comment,
		Rating:  req.Rating,
	})
	if err != nil {
		s.logger.WithError(err).WithFields(logrus.Fields{
			"requestID": req.RequestID,
			"rating":    req.Rating,
		}).Error("failed to accept ticket solution in InvGate")
		return nil, errors.NewAppError(
			errors.ErrCodeExternalService,
			"failed to accept ticket solution in external service",
			err,
		)
	}

	return resp, nil
}

func (s *service) RejectTicketSolution(ctx context.Context, req TicketSolutionRejectRequest) (map[string]interface{}, error) {
	if req.RequestID <= 0 {
		return nil, errors.NewAppError(
			errors.ErrCodeInvalidInput,
			"request_id must be a positive integer",
			nil,
		)
	}

	if strings.TrimSpace(req.Comment) == "" {
		return nil, errors.NewAppError(
			errors.ErrCodeInvalidInput,
			"comment is required",
			nil,
		)
	}

	resp, err := s.client.SolutionReject(ctx, invgate.SolutionRejectPayload{
		ID:      req.RequestID,
		Comment: req.Comment,
	})
	if err != nil {
		s.logger.WithError(err).WithFields(logrus.Fields{
			"requestID": req.RequestID,
		}).Error("failed to reject ticket solution in InvGate")
		return nil, errors.NewAppError(
			errors.ErrCodeExternalService,
			"failed to reject ticket solution in external service",
			err,
		)
	}

	return resp, nil
}

