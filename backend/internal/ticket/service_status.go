package ticket

// getStatusName returns status name from status_id.
func getStatusName(statusID interface{}) string {
	statusMap := map[int]string{
		1: "New",
		2: "Open",
		3: "Pending",
		4: "Waiting",
		5: "Resolved",
		6: "Closed",
		7: "Rejected",
		8: "Canceled",
	}

	var id int
	switch v := statusID.(type) {
	case int:
		id = v
	case int64:
		id = int(v)
	case float64:
		id = int(v)
	default:
		return ""
	}

	if name, ok := statusMap[id]; ok {
		return name
	}
	return ""
}

