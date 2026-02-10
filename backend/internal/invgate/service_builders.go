package invgate

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"math"
	"mime/multipart"
	"net/http"
	"strconv"
	"time"

	"werk-ticketing/internal/constants"
)

func (s *service) CreateTicketWithAttachments(ctx context.Context, payload CreateTicketPayload, files []*multipart.FileHeader) (map[string]interface{}, error) {
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

		body, contentType, err := s.buildTicketMultipartBody(payload, files)
		if err != nil {
			return nil, fmt.Errorf("failed to build multipart body: %w", err)
		}

		result, err, statusCode := s.doRawRequestSingle(ctx, http.MethodPost, "incident", nil, body, contentType)
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

func (s *service) buildTicketMultipartBody(payload CreateTicketPayload, files []*multipart.FileHeader) (*bytes.Buffer, string, error) {
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	writeField := func(name, value string) error {
		return writer.WriteField(name, value)
	}

	if err := writeField("source_id", strconv.Itoa(payload.SourceID)); err != nil {
		return nil, "", err
	}
	if err := writeField("creator_id", strconv.Itoa(payload.CreatorID)); err != nil {
		return nil, "", err
	}
	if err := writeField("customer_id", strconv.Itoa(payload.CustomerID)); err != nil {
		return nil, "", err
	}
	if err := writeField("category_id", strconv.Itoa(payload.CategoryID)); err != nil {
		return nil, "", err
	}
	if err := writeField("type_id", strconv.Itoa(payload.TypeID)); err != nil {
		return nil, "", err
	}
	if err := writeField("priority_id", strconv.Itoa(payload.PriorityID)); err != nil {
		return nil, "", err
	}
	if err := writeField("title", payload.Title); err != nil {
		return nil, "", err
	}
	if err := writeField("description", payload.Description); err != nil {
		return nil, "", err
	}
	if err := writeField("date", strconv.Itoa(payload.DateOcurred)); err != nil {
		return nil, "", err
	}

	for _, fileHeader := range files {
		if fileHeader == nil {
			continue
		}

		part, err := writer.CreateFormFile("attachments[]", fileHeader.Filename)
		if err != nil {
			return nil, "", err
		}

		file, err := fileHeader.Open()
		if err != nil {
			return nil, "", err
		}

		if _, err := io.Copy(part, file); err != nil {
			file.Close()
			return nil, "", err
		}

		file.Close()
	}

	contentType := writer.FormDataContentType()
	if err := writer.Close(); err != nil {
		return nil, "", err
	}

	return body, contentType, nil
}

func (s *service) buildUpdateTicketMultipartBody(payload UpdateTicketPayload) (*bytes.Buffer, string, error) {
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	writeField := func(name, value string) error {
		return writer.WriteField(name, value)
	}

	if err := writeField("id", strconv.Itoa(payload.ID)); err != nil {
		return nil, "", err
	}

	if payload.SourceID > 0 {
		if err := writeField("source_id", strconv.Itoa(payload.SourceID)); err != nil {
			return nil, "", err
		}
	}
	if payload.CreatorID > 0 {
		if err := writeField("creator_id", strconv.Itoa(payload.CreatorID)); err != nil {
			return nil, "", err
		}
	}
	if payload.CustomerID > 0 {
		if err := writeField("customer_id", strconv.Itoa(payload.CustomerID)); err != nil {
			return nil, "", err
		}
	}
	if payload.CategoryID > 0 {
		if err := writeField("category_id", strconv.Itoa(payload.CategoryID)); err != nil {
			return nil, "", err
		}
	}
	if payload.TypeID > 0 {
		if err := writeField("type_id", strconv.Itoa(payload.TypeID)); err != nil {
			return nil, "", err
		}
	}
	if payload.PriorityID > 0 {
		if err := writeField("priority_id", strconv.Itoa(payload.PriorityID)); err != nil {
			return nil, "", err
		}
	}
	if payload.Title != "" {
		if err := writeField("title", payload.Title); err != nil {
			return nil, "", err
		}
	}
	if payload.Description != "" {
		if err := writeField("description", payload.Description); err != nil {
			return nil, "", err
		}
	}
	if payload.DateOcurred > 0 {
		if err := writeField("date", strconv.Itoa(payload.DateOcurred)); err != nil {
			return nil, "", err
		}
	}

	contentType := writer.FormDataContentType()
	if err := writer.Close(); err != nil {
		return nil, "", err
	}

	return body, contentType, nil
}

func (s *service) buildSolutionAcceptMultipartBody(payload SolutionAcceptPayload) (*bytes.Buffer, string, error) {
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	writeField := func(name, value string) error {
		return writer.WriteField(name, value)
	}

	if err := writeField("id", strconv.Itoa(payload.ID)); err != nil {
		return nil, "", err
	}
	if err := writeField("rating", strconv.Itoa(payload.Rating)); err != nil {
		return nil, "", err
	}
	if err := writeField("comment", payload.Comment); err != nil {
		return nil, "", err
	}

	contentType := writer.FormDataContentType()
	if err := writer.Close(); err != nil {
		return nil, "", err
	}

	return body, contentType, nil
}

func (s *service) buildSolutionRejectMultipartBody(payload SolutionRejectPayload) (*bytes.Buffer, string, error) {
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	writeField := func(name, value string) error {
		return writer.WriteField(name, value)
	}

	if err := writeField("id", strconv.Itoa(payload.ID)); err != nil {
		return nil, "", err
	}
	if err := writeField("comment", payload.Comment); err != nil {
		return nil, "", err
	}

	contentType := writer.FormDataContentType()
	if err := writer.Close(); err != nil {
		return nil, "", err
	}

	return body, contentType, nil
}

func (s *service) buildCommentMultipartBody(requestID, authorID int, comment string, files []*multipart.FileHeader) (*bytes.Buffer, string, error) {
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	writeField := func(name, value string) error {
		return writer.WriteField(name, value)
	}

	if err := writeField("request_id", strconv.Itoa(requestID)); err != nil {
		return nil, "", err
	}
	if err := writeField("author_id", strconv.Itoa(authorID)); err != nil {
		return nil, "", err
	}
	if err := writeField("comment", comment); err != nil {
		return nil, "", err
	}

	for _, fileHeader := range files {
		if fileHeader == nil {
			continue
		}

		part, err := writer.CreateFormFile("attachments[]", fileHeader.Filename)
		if err != nil {
			return nil, "", err
		}

		file, err := fileHeader.Open()
		if err != nil {
			return nil, "", err
		}

		if _, err := io.Copy(part, file); err != nil {
			file.Close()
			return nil, "", err
		}

		file.Close()
	}

	contentType := writer.FormDataContentType()
	if err := writer.Close(); err != nil {
		return nil, "", err
	}

	return body, contentType, nil
}
