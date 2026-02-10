package invgate

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"mime"
	"net/http"
	"net/url"
)

func (s *service) GetTicketAttachment(ctx context.Context, attachmentID string) ([]byte, string, string, error) {
	params := url.Values{}
	params.Set("id", attachmentID)

	data, filename, contentType, err := s.doRawRequestBytes(ctx, http.MethodGet, "incident.attachment", params)
	if err != nil {
		return nil, "", "", err
	}
	return data, filename, contentType, nil
}

func (s *service) GetTicketAttachmentInfo(ctx context.Context, attachmentID string) (map[string]interface{}, error) {
	params := url.Values{}
	params.Set("id", attachmentID)

	fullURL := s.cfg.ArmMadaBaseURL + "incident.attachment"
	if len(params) > 0 {
		fullURL = fmt.Sprintf("%s?%s", fullURL, params.Encode())
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, fullURL, nil)
	if err != nil {
		return nil, err
	}

	req.SetBasicAuth(s.cfg.ArmMadaUsername, s.cfg.ArmMadaPassword)
	req.Header.Set("Accept", "application/json")

	resp, err := s.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		data, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("armmada error (status %d): %s", resp.StatusCode, string(data))
	}

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var decoded map[string]interface{}
	if err := json.Unmarshal(data, &decoded); err == nil {
		if dataField, ok := decoded["data"].(map[string]interface{}); ok {
			return dataField, nil
		}
		return decoded, nil
	}

	return nil, fmt.Errorf("failed to decode ArmMada response: %w", err)
}

func parseFilename(contentDisposition string) string {
	if contentDisposition == "" {
		return ""
	}

	_, params, err := mime.ParseMediaType(contentDisposition)
	if err != nil {
		return ""
	}

	if filename, ok := params["filename"]; ok {
		return filename
	}
	return ""
}
