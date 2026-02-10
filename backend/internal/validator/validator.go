package validator

import (
	"regexp"
	"strings"

	"github.com/go-playground/validator/v10"
)

var (
	emailRegex = regexp.MustCompile(`^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$`)
	validate   = validator.New()
)

// ValidateEmail validates email format
func ValidateEmail(email string) bool {
	if email == "" {
		return false
	}
	return emailRegex.MatchString(email)
}

// ValidatePassword validates password (minimum 6 characters)
func ValidatePassword(password string) bool {
	return len(password) >= 6
}

// ValidateRequired validates that a string is not empty (after trimming)
func ValidateRequired(value string) bool {
	return strings.TrimSpace(value) != ""
}

// ValidateRequiredFields validates multiple required fields
func ValidateRequiredFields(fields map[string]string) []string {
	var missing []string
	for name, value := range fields {
		if !ValidateRequired(value) {
			missing = append(missing, name)
		}
	}
	return missing
}

// ValidateStruct validates a struct using go-playground/validator
func ValidateStruct(s interface{}) error {
	return validate.Struct(s)
}

// GetValidator returns the validator instance for custom usage
func GetValidator() *validator.Validate {
	return validate
}

