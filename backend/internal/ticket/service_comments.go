package ticket

import (
	"context"

	"github.com/sirupsen/logrus"

	"werk-ticketing/internal/errors"
)

func (s *service) AddTicketComment(ctx context.Context, req TicketCommentRequest, authorEmail string) (map[string]interface{}, error) {
	user, err := s.userRepo.GetByEmail(ctx, authorEmail)
	if err != nil {
		s.logger.WithError(err).WithField("authorEmail", authorEmail).Error("failed to get user by email")
		return nil, errors.NewAppError(
			errors.ErrCodeInternal,
			"failed to retrieve user information",
			err,
		)
	}
	if user == nil {
		return nil, errors.NewAppError(
			errors.ErrCodeNotFound,
			"user not found",
			nil,
		)
	}

	authorID := user.InvGateUserID

	resp, err := s.client.AddTicketComment(ctx, req.RequestID, authorID, req.Comment, req.AttachmentFiles)
	if err != nil {
		s.logger.WithError(err).WithFields(logrus.Fields{
			"requestID": req.RequestID,
			"authorID":  authorID,
		}).Error("failed to add comment to InvGate ticket")
		return nil, errors.NewAppError(
			errors.ErrCodeExternalService,
			"failed to add comment to ticket",
			err,
		)
	}

	return resp, nil
}

func (s *service) GetTicketComments(ctx context.Context, ticketID int) (map[string]interface{}, error) {
	resp, err := s.client.GetTicketComments(ctx, ticketID)
	if err != nil {
		s.logger.WithError(err).WithField("requestID", ticketID).Error("failed to get ticket comments from InvGate")
		return nil, errors.NewAppError(
			errors.ErrCodeExternalService,
			"failed to fetch ticket comments",
			err,
		)
	}
	return resp, nil
}

