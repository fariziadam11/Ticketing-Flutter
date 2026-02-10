package ticket

import (
	"context"

	"github.com/sirupsen/logrus"

	"werk-ticketing/internal/invgate"
	"werk-ticketing/internal/user"
)

// Service handles ticket business logic.
type Service interface {
	CreateTicket(ctx context.Context, req TicketRequest, creatorEmail string) (map[string]interface{}, error)
	GetTickets(ctx context.Context, creatorID string, page, limit int) (map[string]interface{}, error)
	GetTicketDetail(ctx context.Context, ticketID string) (map[string]interface{}, error)
	GetCategories(ctx context.Context) (map[string]interface{}, error)
	GetTicketMeta(ctx context.Context) (map[string]interface{}, error)
	GetStatuses(ctx context.Context) (map[string]interface{}, error)
	AddTicketComment(ctx context.Context, req TicketCommentRequest, authorEmail string) (map[string]interface{}, error)
	GetTicketComments(ctx context.Context, ticketID int) (map[string]interface{}, error)
	GetTicketAttachment(ctx context.Context, attachmentID string) ([]byte, string, string, error)
	GetTicketAttachmentInfo(ctx context.Context, attachmentID string) (map[string]interface{}, error)
	UpdateTicketSolution(ctx context.Context, req TicketSolutionRequest) (map[string]interface{}, error)
	RejectTicketSolution(ctx context.Context, req TicketSolutionRejectRequest) (map[string]interface{}, error)
	UpdateTicket(ctx context.Context, ticketID int, req TicketUpdateRequest) (map[string]interface{}, error)
	GetInvGateUser(ctx context.Context, userID int) (map[string]interface{}, error)
	GetArticlesByCategory(ctx context.Context, categoryID int) (map[string]interface{}, error)
}

type service struct {
	client     invgate.Service
	repository Repository
	userRepo   user.Repository
	logger     *logrus.Logger
}

// NewService returns ticket service.
func NewService(client invgate.Service, repo Repository, userRepo user.Repository, logger *logrus.Logger) Service {
	return &service{
		client:     client,
		repository: repo,
		userRepo:   userRepo,
		logger:     logger,
	}
}
