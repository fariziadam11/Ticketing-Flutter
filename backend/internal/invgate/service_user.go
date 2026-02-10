package invgate

import (
	"context"
	"net/http"
	"net/url"
	"strconv"
)

func (s *service) CreateUser(ctx context.Context, payload CreateUserPayload) (map[string]interface{}, error) {
	return s.doRequest(ctx, http.MethodPost, "user", payload, nil)
}

func (s *service) DeleteUser(ctx context.Context, userID int) error {
	params := url.Values{}
	params.Set("id", strconv.Itoa(userID))
	_, err := s.doRequest(ctx, http.MethodDelete, "user", nil, params)
	return err
}

func (s *service) GetUser(ctx context.Context, userID int) (map[string]interface{}, error) {
	params := url.Values{}
	params.Set("id", strconv.Itoa(userID))
	return s.doRequest(ctx, http.MethodGet, "user", nil, params)
}

func (s *service) GetUserByEmail(ctx context.Context, email string) (map[string]interface{}, error) {
	params := url.Values{}
	params.Set("email", email)
	return s.doRequest(ctx, http.MethodGet, "user.by", nil, params)
}

