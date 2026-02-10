package ticket

import "mime/multipart"

// TicketRequest represents payload for creating InvGate ticket.
type TicketRequest struct {
	SourceID    int    `json:"source_id"`
	CreatorID   int    `json:"creator_id"`
	CustomerID  int    `json:"customer_id"`
	CategoryID  int    `json:"category_id"`
	TypeID      int    `json:"type_id"`
	PriorityID  int    `json:"priority_id"`
	Title       string `json:"title"`
	Description string `json:"description"`
	DateOcurred int    `json:"date_ocurred"` // UNIX timestamp

	// AttachmentFiles contains raw files when the request is multipart/form-data.
	AttachmentFiles []*multipart.FileHeader `json:"-"`
}

// TicketListResponse wraps ticket list response.
type TicketListResponse struct {
	PageKey string        `json:"page_key,omitempty"`
	Data    []interface{} `json:"data"`
}

// TicketCommentRequest represents payload for adding a comment to a ticket.
type TicketCommentRequest struct {
	RequestID       int                     `json:"request_id"`
	AuthorID        int                     `json:"author_id"`
	Comment         string                  `json:"comment"`
	AttachmentFiles []*multipart.FileHeader `json:"-"`
}

// TicketSolutionRequest represents payload for accepting/solving a ticket.
// This is used to send solution comment and rating to InvGate.
type TicketSolutionRequest struct {
	RequestID int    `json:"request_id"`
	Rating    int    `json:"rating"`
	Comment   string `json:"comment"`
}

// TicketSolutionRejectRequest represents payload for rejecting a ticket solution.
// It only carries the request ID and rejection comment (no rating).
type TicketSolutionRejectRequest struct {
	RequestID int    `json:"request_id"`
	Comment   string `json:"comment"`
}

// TicketUpdateRequest represents payload for updating an existing ticket.
// All fields except ID are optional - only provided fields will be updated.
type TicketUpdateRequest struct {
	SourceID    *int    `json:"source_id,omitempty"`
	CreatorID   *int    `json:"creator_id,omitempty"`
	CustomerID  *int    `json:"customer_id,omitempty"`
	CategoryID  *int    `json:"category_id,omitempty"`
	TypeID      *int    `json:"type_id,omitempty"`
	PriorityID  *int    `json:"priority_id,omitempty"`
	Title       *string `json:"title,omitempty"`
	Description *string `json:"description,omitempty"`
	DateOcurred *int    `json:"date_ocurred,omitempty"` // UNIX timestamp
}
