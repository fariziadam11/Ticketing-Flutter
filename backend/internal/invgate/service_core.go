package invgate

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"math"
	"net/http"
	"net/url"
	"time"

	"werk-ticketing/internal/constants"
)

func (s *service) doRequest(ctx context.Context, method, path string, body interface{}, params url.Values) (map[string]interface{}, error) {
	var buf io.Reader
	if body != nil {
		payload, err := json.Marshal(body)
		if err != nil {
			return nil, err
		}
		buf = bytes.NewBuffer(payload)
	}
	return s.doRawRequest(ctx, method, path, params, buf, "application/json")
}

func (s *service) doRawRequest(ctx context.Context, method, path string, params url.Values, body io.Reader, contentType string) (map[string]interface{}, error) {
	return s.doRawRequestWithRetry(ctx, method, path, params, body, contentType)
}

func (s *service) doRawRequestWithRetry(ctx context.Context, method, path string, params url.Values, body io.Reader, contentType string) (map[string]interface{}, error) {
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

		result, err, statusCode := s.doRawRequestSingle(ctx, method, path, params, body, contentType)
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

func (s *service) doRawRequestSingle(ctx context.Context, method, path string, params url.Values, body io.Reader, contentType string) (map[string]interface{}, error, int) {
	fullURL := s.cfg.ArmMadaBaseURL + path
	if len(params) > 0 {
		fullURL = fmt.Sprintf("%s?%s", fullURL, params.Encode())
	}

	req, err := http.NewRequestWithContext(ctx, method, fullURL, body)
	if err != nil {
		return nil, err, 0
	}

	req.SetBasicAuth(s.cfg.ArmMadaUsername, s.cfg.ArmMadaPassword)
	if contentType != "" {
		req.Header.Set("Content-Type", contentType)
	}

	resp, err := s.client.Do(req)
	if err != nil {
		return nil, err, 0
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		data, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("armmada error (status %d): %s", resp.StatusCode, string(data)), resp.StatusCode
	}

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err, resp.StatusCode
	}

	var decoded map[string]interface{}
	if err := json.Unmarshal(data, &decoded); err == nil {
		return decoded, nil, resp.StatusCode
	}

	var arrayResp []interface{}
	if err := json.Unmarshal(data, &arrayResp); err == nil {
		return map[string]interface{}{
			"data": arrayResp,
		}, nil, resp.StatusCode
	}

	return nil, fmt.Errorf("failed to decode ArmMada response: %w", err), resp.StatusCode
}

func (s *service) doRawRequestBytes(ctx context.Context, method, path string, params url.Values) ([]byte, string, string, error) {
	fullURL := s.cfg.ArmMadaBaseURL + path
	if len(params) > 0 {
		fullURL = fmt.Sprintf("%s?%s", fullURL, params.Encode())
	}

	req, err := http.NewRequestWithContext(ctx, method, fullURL, nil)
	if err != nil {
		return nil, "", "", err
	}

	req.SetBasicAuth(s.cfg.ArmMadaUsername, s.cfg.ArmMadaPassword)

	resp, err := s.client.Do(req)
	if err != nil {
		return nil, "", "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		data, _ := io.ReadAll(resp.Body)
		return nil, "", "", fmt.Errorf("armmada error (status %d): %s", resp.StatusCode, string(data))
	}

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, "", "", err
	}

	contentType := resp.Header.Get("Content-Type")
	filename := parseFilename(resp.Header.Get("Content-Disposition"))

	return data, filename, contentType, nil
}

func isRetryableError(err error, statusCode int) bool {
	if err != nil {
		return true
	}
	if statusCode >= 500 {
		return true
	}
	if statusCode == 429 {
		return true
	}
	return false
}
