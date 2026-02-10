package auth

import "fmt"

func extractInvGateUserID(resp map[string]interface{}) (int, error) {
	if resp == nil {
		return 0, fmt.Errorf("empty response from InvGate")
	}

	rawID, ok := resp["id"]
	if !ok {
		return 0, fmt.Errorf("user ID not found in InvGate response")
	}

	switch v := rawID.(type) {
	case float64:
		return int(v), nil
	case int:
		return v, nil
	case int64:
		return int(v), nil
	default:
		return 0, fmt.Errorf("unexpected type for InvGate user ID: %T", rawID)
	}
}

