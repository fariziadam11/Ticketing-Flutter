package ticket

// Handler wires ticket service with HTTP endpoints.
type Handler struct {
	service Service
}

// NewHandler creates ticket handler.
func NewHandler(service Service) *Handler {
	return &Handler{service: service}
}
