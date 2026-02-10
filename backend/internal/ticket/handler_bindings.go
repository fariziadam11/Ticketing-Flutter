package ticket

import (
	"encoding/json"
	"fmt"
	"mime/multipart"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
)

// bindTicketMultipart parses multipart form-data into TicketRequest.
func bindTicketMultipart(c *gin.Context) (TicketRequest, error) {
	const maxMemory = 32 << 20 // 32MB
	if err := c.Request.ParseMultipartForm(maxMemory); err != nil {
		return TicketRequest{}, fmt.Errorf("invalid multipart form: %w", err)
	}

	form := c.Request.MultipartForm
	values := form.Value

	if rawReq := getFirstValue(values, "request"); rawReq != "" {
		var req TicketRequest
		if err := json.Unmarshal([]byte(rawReq), &req); err != nil {
			return TicketRequest{}, fmt.Errorf("invalid request JSON: %w", err)
		}
		req.AttachmentFiles = collectAttachmentFiles(form.File)
		return req, nil
	}

	parseInt := func(key string) (int, error) {
		vals, ok := values[key]
		if !ok || len(vals) == 0 || strings.TrimSpace(vals[0]) == "" {
			return 0, fmt.Errorf("%s is required", key)
		}
		parsed, err := strconv.Atoi(vals[0])
		if err != nil {
			return 0, fmt.Errorf("invalid %s", key)
		}
		return parsed, nil
	}

	sourceID, err := parseInt("source_id")
	if err != nil {
		return TicketRequest{}, err
	}
	categoryID, err := parseInt("category_id")
	if err != nil {
		return TicketRequest{}, err
	}
	typeID, err := parseInt("type_id")
	if err != nil {
		return TicketRequest{}, err
	}
	priorityID, err := parseInt("priority_id")
	if err != nil {
		return TicketRequest{}, err
	}

	title := getFirstValue(values, "title")
	description := getFirstValue(values, "description")

	dateOcurred := 0
	if dateStr := getFirstValue(values, "date_ocurred"); dateStr != "" {
		if parsed, err := strconv.Atoi(dateStr); err == nil {
			dateOcurred = parsed
		}
	}
	if dateOcurred == 0 {
		dateOcurred = int(time.Now().Unix())
	}

	attachments := collectAttachmentFiles(form.File)

	return TicketRequest{
		SourceID:        sourceID,
		CreatorID:       0,
		CustomerID:      0,
		CategoryID:      categoryID,
		TypeID:          typeID,
		PriorityID:      priorityID,
		Title:           title,
		Description:     description,
		DateOcurred:     dateOcurred,
		AttachmentFiles: attachments,
	}, nil
}

// bindCommentMultipart parses multipart form-data for ticket comments.
func bindCommentMultipart(c *gin.Context) (TicketCommentRequest, error) {
	const maxMemory = 32 << 20 // 32MB
	if err := c.Request.ParseMultipartForm(maxMemory); err != nil {
		return TicketCommentRequest{}, fmt.Errorf("invalid multipart form: %w", err)
	}

	form := c.Request.MultipartForm
	values := form.Value

	comment := getFirstValue(values, "comment")
	if strings.TrimSpace(comment) == "" {
		return TicketCommentRequest{}, fmt.Errorf("comment is required")
	}

	attachments := collectAttachmentFiles(form.File)

	return TicketCommentRequest{
		Comment:         comment,
		AttachmentFiles: attachments,
	}, nil
}

func getFirstValue(values map[string][]string, key string) string {
	if vals, ok := values[key]; ok && len(vals) > 0 {
		return vals[0]
	}
	return ""
}

func collectAttachmentFiles(files map[string][]*multipart.FileHeader) []*multipart.FileHeader {
	var result []*multipart.FileHeader
	if slice, ok := files["attachments"]; ok {
		result = append(result, slice...)
	}
	if slice, ok := files["attachments[]"]; ok {
		result = append(result, slice...)
	}
	return result
}

