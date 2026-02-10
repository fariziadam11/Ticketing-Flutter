package invgate

import (
	"context"
	"mime/multipart"
	"net/http"
	"net/url"
	"time"

	"werk-ticketing/internal/config"
	"werk-ticketing/internal/constants"
)

// Service defines InvGate Armmada HTTP client contract.
type Service interface {
	CreateUser(ctx context.Context, payload CreateUserPayload) (map[string]interface{}, error)
	DeleteUser(ctx context.Context, userID int) error
	GetUser(ctx context.Context, userID int) (map[string]interface{}, error)
	GetUserByEmail(ctx context.Context, email string) (map[string]interface{}, error)
	CreateTicket(ctx context.Context, payload CreateTicketPayload) (map[string]interface{}, error)
	CreateTicketWithAttachments(ctx context.Context, payload CreateTicketPayload, files []*multipart.FileHeader) (map[string]interface{}, error)
	UpdateTicket(ctx context.Context, payload UpdateTicketPayload) (map[string]interface{}, error)
	SolutionAccept(ctx context.Context, payload SolutionAcceptPayload) (map[string]interface{}, error)
	SolutionReject(ctx context.Context, payload SolutionRejectPayload) (map[string]interface{}, error)
	GetTicketList(ctx context.Context, filters url.Values) (map[string]interface{}, error)
	GetTicketDetail(ctx context.Context, ticketID string) (map[string]interface{}, error)
	GetCategories(ctx context.Context) (map[string]interface{}, error)
	AddTicketComment(ctx context.Context, requestID, authorID int, comment string, files []*multipart.FileHeader) (map[string]interface{}, error)
	GetTicketComments(ctx context.Context, requestID int) (map[string]interface{}, error)
	GetTicketAttachment(ctx context.Context, attachmentID string) ([]byte, string, string, error)
	GetTicketAttachmentInfo(ctx context.Context, attachmentID string) (map[string]interface{}, error)
	AssignUserToCompany(ctx context.Context, companyID int, userIDs []int) error
	AssignUserToGroup(ctx context.Context, groupID int, userIDs []int) error
	AssignUserToLocation(ctx context.Context, locationID int, userIDs []int) error
	GetArticlesByCategory(ctx context.Context, categoryID int) (map[string]interface{}, error)
}

type service struct {
	cfg    *config.Config
	client *http.Client
}

// NewService builds InvGate API client.
func NewService(cfg *config.Config) Service {
	return &service{
		cfg: cfg,
		client: &http.Client{
			Timeout: time.Duration(constants.HTTPClientTimeoutSeconds) * time.Second,
		},
	}
}
