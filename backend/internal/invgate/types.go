package invgate

// CreateTicketPayload matches InvGate create incident schema.
type CreateTicketPayload struct {
	SourceID    int                 `json:"source_id"`
	CreatorID   int                 `json:"creator_id"`
	CustomerID  int                 `json:"customer_id"`
	CategoryID  int                 `json:"category_id"`
	TypeID      int                 `json:"type_id"`
	PriorityID  int                 `json:"priority_id"`
	Title       string              `json:"title"`
	Description string              `json:"description"`
	DateOcurred int                 `json:"date"` // UNIX timestamp - InvGate API uses "date"
	Attachments []AttachmentPayload `json:"attachments,omitempty"`
}

// CreateUserPayload matches InvGate user creation schema.
// NOTE: "pass" is the expected password field name in InvGate.
// We send the plain password only to InvGate; locally we always store the bcrypt hash instead.
// All fields (name, lastname, email, pass) are required.
type CreateUserPayload struct {
	Name     string `json:"name"`
	LastName string `json:"lastname"`
	Email    string `json:"email"`
	Pass     string `json:"pass,omitempty"`
}

// AssignUsersPayload represents the payload to assign users to companies/groups/locations.
type AssignUsersPayload struct {
	ID    int   `json:"id"`
	Users []int `json:"users"`
}

// AttachmentPayload represents attachment reference when creating tickets.
type AttachmentPayload struct {
	ID int `json:"id"`
}

// SolutionAcceptPayload represents the payload to accept/close a ticket solution in InvGate.
// According to InvGate API, it expects:
// - id: request/ticket ID
// - comment: solution comment
// - rating: 1-5 rating for the solution
type SolutionAcceptPayload struct {
	ID      int    `json:"id"`
	Comment string `json:"comment"`
	Rating  int    `json:"rating"`
}

// SolutionRejectPayload represents the payload to reject a ticket solution in InvGate.
// It only requires:
// - id: request/ticket ID
// - comment: rejection reason
type SolutionRejectPayload struct {
	ID      int    `json:"id"`
	Comment string `json:"comment"`
}

// UpdateTicketPayload represents the payload to update an existing ticket in InvGate.
// The id field is required, all other fields are optional and only included if provided.
type UpdateTicketPayload struct {
	ID          int    `json:"id"` // Required: ticket ID
	SourceID    int    `json:"source_id,omitempty"`
	CreatorID   int    `json:"creator_id,omitempty"`
	CustomerID  int    `json:"customer_id,omitempty"`
	CategoryID  int    `json:"category_id,omitempty"`
	TypeID      int    `json:"type_id,omitempty"`
	PriorityID  int    `json:"priority_id,omitempty"`
	Title       string `json:"title,omitempty"`
	Description string `json:"description,omitempty"`
	DateOcurred int    `json:"date_ocurred,omitempty"` // UNIX timestamp - InvGate API uses "date"
}
