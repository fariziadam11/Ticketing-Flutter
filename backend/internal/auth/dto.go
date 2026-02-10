package auth

// RegisterRequest incoming body.
type RegisterRequest struct {
	Name     string `json:"name" binding:"required,min=1,max=100" validate:"required,min=1,max=100"`
	LastName string `json:"lastname" binding:"required,min=1,max=100" validate:"required,min=1,max=100"`
	Email    string `json:"email" binding:"required,email" validate:"required,email"`
	Password string `json:"password" binding:"required,min=6" validate:"required,min=6"`
}

// LoginRequest incoming body.
type LoginRequest struct {
	Email    string `json:"email" binding:"required,email" validate:"required,email"`
	Password string `json:"password" binding:"required,min=6" validate:"required,min=6"`
}

// AuthResponse standard auth payload.
type AuthResponse struct {
	Token        string `json:"token"`
	RefreshToken string `json:"refresh_token,omitempty"`
	Name         string `json:"name"`
	LastName     string `json:"lastname"`
	Email        string `json:"email"`
}

// RefreshTokenRequest request for token refresh
type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required" validate:"required"`
}
