package invgate

import (
	"context"
	"net/http"
	"net/url"
	"strconv"
)

func (s *service) CreateTicket(ctx context.Context, payload CreateTicketPayload) (map[string]interface{}, error) {
	body, contentType, err := s.buildTicketMultipartBody(payload, nil)
	if err != nil {
		return nil, err
	}
	return s.doRawRequest(ctx, http.MethodPost, "incident", nil, body, contentType)
}

func (s *service) UpdateTicket(ctx context.Context, payload UpdateTicketPayload) (map[string]interface{}, error) {
	body, contentType, err := s.buildUpdateTicketMultipartBody(payload)
	if err != nil {
		return nil, err
	}
	return s.doRawRequest(ctx, http.MethodPut, "incident", nil, body, contentType)
}

func (s *service) SolutionAccept(ctx context.Context, payload SolutionAcceptPayload) (map[string]interface{}, error) {
	body, contentType, err := s.buildSolutionAcceptMultipartBody(payload)
	if err != nil {
		return nil, err
	}
	return s.doRawRequest(ctx, http.MethodPut, "incident.solution.accept", nil, body, contentType)
}

func (s *service) SolutionReject(ctx context.Context, payload SolutionRejectPayload) (map[string]interface{}, error) {
	body, contentType, err := s.buildSolutionRejectMultipartBody(payload)
	if err != nil {
		return nil, err
	}
	return s.doRawRequest(ctx, http.MethodPut, "incident.solution.reject", nil, body, contentType)
}

func (s *service) GetTicketList(ctx context.Context, filters url.Values) (map[string]interface{}, error) {
	if filters == nil {
		filters = url.Values{}
	}
	if s.cfg.ArmMadaPageKey != "" && filters.Get("page_key") == "" {
		filters.Set("page_key", s.cfg.ArmMadaPageKey)
	}
	return s.doRequest(ctx, http.MethodGet, "incidents", nil, filters)
}

func (s *service) GetTicketDetail(ctx context.Context, ticketID string) (map[string]interface{}, error) {
	params := url.Values{}
	params.Set("id", ticketID)
	return s.doRequest(ctx, http.MethodGet, "incident", nil, params)
}

func (s *service) GetCategories(ctx context.Context) (map[string]interface{}, error) {
	return s.doRequest(ctx, http.MethodGet, "categories", nil, nil)
}

func (s *service) GetArticlesByCategory(ctx context.Context, categoryID int) (map[string]interface{}, error) {
	params := url.Values{}
	params.Set("category_id", strconv.Itoa(categoryID))

	resp, err := s.doRequest(ctx, http.MethodGet, "kb.articles.by.category", nil, params)
	if err != nil {
		return nil, err
	}

	if data, ok := resp["data"].([]interface{}); ok {
		return map[string]interface{}{
			"data": data,
		}, nil
	}

	return resp, nil
}

