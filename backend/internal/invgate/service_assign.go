package invgate

import (
	"context"
	"net/http"
)

func (s *service) AssignUserToCompany(ctx context.Context, companyID int, userIDs []int) error {
	return s.assignUsers(ctx, "companies.users", companyID, userIDs)
}

func (s *service) AssignUserToGroup(ctx context.Context, groupID int, userIDs []int) error {
	return s.assignUsers(ctx, "groups.users", groupID, userIDs)
}

func (s *service) AssignUserToLocation(ctx context.Context, locationID int, userIDs []int) error {
	return s.assignUsers(ctx, "locations.users", locationID, userIDs)
}

func (s *service) assignUsers(ctx context.Context, endpoint string, entityID int, userIDs []int) error {
	payload := AssignUsersPayload{
		ID:    entityID,
		Users: userIDs,
	}

	_, err := s.doRequest(ctx, http.MethodPost, endpoint, payload, nil)
	return err
}

