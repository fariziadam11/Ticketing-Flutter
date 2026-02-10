package invgate

import (
	"context"
	"fmt"
	"math"
	"mime/multipart"
	"net/http"
	"net/url"
	"strconv"
	"time"

	"werk-ticketing/internal/constants"
)

func (s *service) AddTicketComment(ctx context.Context, requestID, authorID int, comment string, files []*multipart.FileHeader) (map[string]interface{}, error) {
	if len(files) == 0 {
		payload := map[string]interface{}{
			"request_id": requestID,
			"author_id":  authorID,
			"comment":    comment,
		}
		return s.doRequest(ctx, http.MethodPost, "incident.comment", payload, nil)
	}

	var lastErr error
	delay := time.Duration(constants.RetryInitialDelayMs) * time.Millisecond

	for attempt := 0; attempt < constants.RetryMaxAttempts; attempt++ {
		if attempt > 0 {
			select {
			case <-ctx.Done():
				return nil, ctx.Err()
			case <-time.After(delay):
			}
			delay = time.Duration(math.Min(
				float64(delay.Milliseconds())*constants.RetryBackoffMultiplier,
				float64(constants.RetryMaxDelayMs),
			)) * time.Millisecond
		}

		body, contentType, err := s.buildCommentMultipartBody(requestID, authorID, comment, files)
		if err != nil {
			return nil, fmt.Errorf("failed to build multipart body: %w", err)
		}

		result, err, statusCode := s.doRawRequestSingle(ctx, http.MethodPost, "incident.comment", nil, body, contentType)
		if err == nil {
			return result, nil
		}

		lastErr = err
		if !isRetryableError(err, statusCode) {
			return nil, err
		}
	}

	return nil, fmt.Errorf("request failed after %d attempts: %w", constants.RetryMaxAttempts, lastErr)
}

func (s *service) GetTicketComments(ctx context.Context, requestID int) (map[string]interface{}, error) {
	params := url.Values{}
	params.Set("request_id", strconv.Itoa(requestID))
	return s.doRequest(ctx, http.MethodGet, "incident.comment", nil, params)
}
