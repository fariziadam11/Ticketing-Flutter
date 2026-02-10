package ticket

import (
	"fmt"
	"strconv"
)

// extractInvGateID extracts the InvGate ID from the response.
// It handles various types that might be returned (string, int, float64, etc.)
func extractInvGateID(resp map[string]interface{}) (string, error) {
	// Try "id" field first
	if id, ok := resp["id"]; ok {
		return convertToString(id)
	}

	// Try "request_id" field (common in InvGate responses)
	if requestID, ok := resp["request_id"]; ok {
		return convertToString(requestID)
	}

	// Try "incident_id" field
	if incidentID, ok := resp["incident_id"]; ok {
		return convertToString(incidentID)
	}

	return "", fmt.Errorf("invGate ID not found in response")
}

// convertToString converts various types to string
func convertToString(v interface{}) (string, error) {
	switch val := v.(type) {
	case string:
		return val, nil
	case int:
		return strconv.Itoa(val), nil
	case int64:
		return strconv.FormatInt(val, 10), nil
	case float64:
		// JSON numbers are decoded as float64
		return strconv.FormatFloat(val, 'f', -1, 64), nil
	default:
		return fmt.Sprintf("%v", val), nil
	}
}
