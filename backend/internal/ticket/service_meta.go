package ticket

import (
	"context"
	"strconv"

	"werk-ticketing/internal/errors"
)

func (s *service) GetCategories(ctx context.Context) (map[string]interface{}, error) {
	resp, err := s.client.GetCategories(ctx)
	if err != nil {
		s.logger.WithError(err).Error("failed to get categories from InvGate")
		return nil, errors.NewAppError(
			errors.ErrCodeExternalService,
			"failed to fetch categories from external service",
			err,
		)
	}

	filteredCategories := s.filterAllowedCategories(resp)

	return map[string]interface{}{
		"data": filteredCategories,
	}, nil
}

func (s *service) GetTicketMeta(ctx context.Context) (map[string]interface{}, error) {
	types := []map[string]interface{}{
		{"id": 1, "name": "Incident"},
		{"id": 2, "name": "Service Request"},
		{"id": 3, "name": "Question"},
		{"id": 4, "name": "Problem"},
		{"id": 5, "name": "Change"},
		{"id": 6, "name": "Major Incident"},
	}

	priorities := []map[string]interface{}{
		{"id": 1, "name": "Low"},
		{"id": 2, "name": "Medium"},
		{"id": 3, "name": "High"},
		{"id": 4, "name": "Urgent"},
		{"id": 5, "name": "Critical"},
	}

	return map[string]interface{}{
		"types":      types,
		"priorities": priorities,
	}, nil
}

func (s *service) GetStatuses(ctx context.Context) (map[string]interface{}, error) {
	statuses := []map[string]interface{}{
		{"id": 1, "name": "New"},
		{"id": 2, "name": "Open"},
		{"id": 3, "name": "Pending"},
		{"id": 4, "name": "Waiting"},
		{"id": 5, "name": "Resolved"},
		{"id": 6, "name": "Closed"},
		{"id": 7, "name": "Rejected"},
		{"id": 8, "name": "Canceled"},
	}

	return map[string]interface{}{
		"data": statuses,
	}, nil
}

func (s *service) GetTicketAttachment(ctx context.Context, attachmentID string) ([]byte, string, string, error) {
	data, filename, contentType, err := s.client.GetTicketAttachment(ctx, attachmentID)
	if err != nil {
		s.logger.WithError(err).WithField("attachmentID", attachmentID).Error("failed to get ticket attachment from InvGate")
		return nil, "", "", errors.NewAppError(
			errors.ErrCodeExternalService,
			"failed to fetch attachment",
			err,
		)
	}

	if contentType == "" {
		contentType = "application/octet-stream"
	}

	return data, filename, contentType, nil
}

func (s *service) GetTicketAttachmentInfo(ctx context.Context, attachmentID string) (map[string]interface{}, error) {
	return s.client.GetTicketAttachmentInfo(ctx, attachmentID)
}

func (s *service) GetArticlesByCategory(ctx context.Context, categoryID int) (map[string]interface{}, error) {
	if categoryID <= 0 {
		return nil, errors.NewAppError(
			errors.ErrCodeInvalidInput,
			"category_id must be a positive integer",
			nil,
		)
	}

	resp, err := s.client.GetArticlesByCategory(ctx, categoryID)
	if err != nil {
		s.logger.WithError(err).WithField("categoryID", categoryID).Error("failed to get articles from InvGate")
		return nil, errors.NewAppError(
			errors.ErrCodeExternalService,
			"failed to fetch articles from external service",
			err,
		)
	}

	return resp, nil
}

func (s *service) filterAllowedCategories(resp map[string]interface{}) []map[string]interface{} {
	allowedIDs := map[int]bool{
		115: true, // ESS
		116: true, // Kehadiran
		117: true, // Personalia
		118: true, // Penggajian
		119: true, // CRM
		120: true, // LMS
		121: true, // Intranet
		122: true, // Job Portal
		123: true, // Pengaturan Perusahaan
	}

	var categories []interface{}

	if data, ok := resp["data"]; ok {
		if arr, ok := data.([]interface{}); ok {
			categories = arr
		}
	} else if arr, ok := resp["categories"].([]interface{}); ok {
		categories = arr
	} else {
		for _, v := range resp {
			if arr, ok := v.([]interface{}); ok {
				categories = arr
				break
			}
		}
	}

	var filtered []map[string]interface{}
	for _, item := range categories {
		category, ok := item.(map[string]interface{})
		if !ok {
			continue
		}

		var id int
		if idVal, exists := category["id"]; exists {
			switch v := idVal.(type) {
			case int:
				id = v
			case int64:
				id = int(v)
			case float64:
				id = int(v)
			case string:
				parsed, err := strconv.Atoi(v)
				if err != nil {
					continue
				}
				id = parsed
			default:
				continue
			}
		} else {
			continue
		}

		if allowedIDs[id] {
			filtered = append(filtered, category)
		}
	}

	return filtered
}

