package ticket

import (
	"context"

	"github.com/sirupsen/logrus"

	"werk-ticketing/internal/errors"
	"werk-ticketing/internal/invgate"
)

func (s *service) UpdateTicket(ctx context.Context, ticketID int, req TicketUpdateRequest) (map[string]interface{}, error) {
	if ticketID <= 0 {
		return nil, errors.NewAppError(
			errors.ErrCodeInvalidInput,
			"ticket id must be a positive integer",
			nil,
		)
	}

	payload := invgate.UpdateTicketPayload{
		ID: ticketID,
	}

	if req.SourceID != nil {
		payload.SourceID = *req.SourceID
	}
	if req.CreatorID != nil {
		payload.CreatorID = *req.CreatorID
	}
	if req.CustomerID != nil {
		payload.CustomerID = *req.CustomerID
	}
	if req.CategoryID != nil {
		payload.CategoryID = *req.CategoryID
	}
	if req.TypeID != nil {
		payload.TypeID = *req.TypeID
	}
	if req.PriorityID != nil {
		payload.PriorityID = *req.PriorityID
	}
	if req.Title != nil {
		payload.Title = *req.Title
	}
	if req.Description != nil {
		payload.Description = *req.Description
	}
	if req.DateOcurred != nil {
		payload.DateOcurred = *req.DateOcurred
	}

	resp, err := s.client.UpdateTicket(ctx, payload)
	if err != nil {
		s.logger.WithError(err).WithFields(logrus.Fields{
			"ticketID": ticketID,
		}).Error("failed to update ticket in InvGate")
		return nil, errors.NewAppError(
			errors.ErrCodeExternalService,
			"failed to update ticket in external service",
			err,
		)
	}

	return resp, nil
}

func (s *service) GetInvGateUser(ctx context.Context, userID int) (map[string]interface{}, error) {
	if userID <= 0 {
		return nil, errors.NewAppError(
			errors.ErrCodeInvalidInput,
			"user_id must be a positive integer",
			nil,
		)
	}

	resp, err := s.client.GetUser(ctx, userID)
	if err != nil {
		s.logger.WithError(err).WithField("userID", userID).Error("failed to get user from InvGate")
		return nil, errors.NewAppError(
			errors.ErrCodeExternalService,
			"failed to fetch user from external service",
			err,
		)
	}

	return resp, nil
}

