package ticket

import (
	"context"
	"fmt"

	"werk-ticketing/internal/errors"
)

func (s *service) GetTickets(ctx context.Context, creatorID string, page, limit int) (map[string]interface{}, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 2
	}
	if limit > 100 {
		limit = 100
	}

	offset := (page - 1) * limit

	totalCount, err := s.repository.CountByCreatorEmail(ctx, creatorID)
	if err != nil {
		s.logger.WithError(err).
			WithField("creatorID", creatorID).
			Error("failed to count tickets from repository")
		return nil, errors.NewAppError(
			errors.ErrCodeInternal,
			"failed to count tickets from database",
			err,
		)
	}

	localTickets, err := s.repository.GetByCreatorEmailPaginated(ctx, creatorID, limit, offset)
	if err != nil {
		s.logger.WithError(err).
			WithField("creatorID", creatorID).
			Error("failed to get tickets from repository")
		return nil, errors.NewAppError(
			errors.ErrCodeInternal,
			"failed to fetch tickets from database",
			err,
		)
	}

	var tickets []map[string]interface{}
	for _, localTicket := range localTickets {
		if localTicket.InvGateID == "" {
			s.logger.WithField("ticketID", localTicket.ID).
				Warn("skipping ticket without InvGate ID")
			continue
		}

		ticketDetail, err := s.client.GetTicketDetail(ctx, localTicket.InvGateID)
		if err != nil {
			s.logger.WithError(err).
				WithField("invGateID", localTicket.InvGateID).
				Warn("failed to get ticket detail from InvGate, skipping")
			continue
		}

		if statusID, ok := ticketDetail["status_id"]; ok {
			ticketDetail["status"] = getStatusName(statusID)
		}

		ticketDetail["inv_gate_id"] = localTicket.InvGateID
		ticketDetail["wrk_ticket_id"] = fmt.Sprintf("WRK-#%s", localTicket.InvGateID)

		tickets = append(tickets, ticketDetail)
	}

	totalPages := int((totalCount + int64(limit) - 1) / int64(limit))
	if totalPages == 0 {
		totalPages = 1
	}

	return map[string]interface{}{
		"data": tickets,
		"pagination": map[string]interface{}{
			"page":        page,
			"limit":       limit,
			"total":       totalCount,
			"total_pages": totalPages,
			"has_next":    page < totalPages,
			"has_prev":    page > 1,
		},
	}, nil
}

func (s *service) GetTicketDetail(ctx context.Context, ticketID string) (map[string]interface{}, error) {
	resp, err := s.client.GetTicketDetail(ctx, ticketID)
	if err != nil {
		s.logger.WithError(err).
			WithField("ticketID", ticketID).
			Error("failed to get ticket detail from InvGate")
		return nil, errors.NewAppError(
			errors.ErrCodeExternalService,
			"failed to fetch ticket detail from external service",
			err,
		)
	}

	if statusID, ok := resp["status_id"]; ok {
		resp["status"] = getStatusName(statusID)
	}

	return resp, nil
}
