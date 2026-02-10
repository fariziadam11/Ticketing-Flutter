package user

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"gorm.io/gorm"
)

// Repository abstracts data persistence for users.
type Repository interface {
	Create(ctx context.Context, user *User) error
	GetByEmail(ctx context.Context, email string) (*User, error)
	Delete(ctx context.Context, id string) error
}

type gormRepository struct {
	db *gorm.DB
}

// NewRepository builds a Gorm-backed user repository.
func NewRepository(db *gorm.DB) Repository {
	return &gormRepository{db: db}
}

func (r *gormRepository) Create(ctx context.Context, user *User) error {
	err := r.db.WithContext(ctx).Create(user).Error
	if err != nil {
		// Check if error is due to duplicate key (unique constraint violation)
		if isDuplicateKeyError(err) {
			return &DuplicateKeyError{
				Field: "email",
				Value: user.Email,
				Err:   err,
			}
		}
		return err
	}
	return nil
}

// DuplicateKeyError represents a duplicate key constraint violation
type DuplicateKeyError struct {
	Field string
	Value string
	Err   error
}

func (e *DuplicateKeyError) Error() string {
	return fmt.Sprintf("duplicate key violation on field '%s' with value '%s'", e.Field, e.Value)
}

func (e *DuplicateKeyError) Unwrap() error {
	return e.Err
}

// isDuplicateKeyError checks if the error is a duplicate key constraint violation
func isDuplicateKeyError(err error) bool {
	if err == nil {
		return false
	}
	
	errStr := strings.ToLower(err.Error())
	
	// MySQL duplicate key error patterns
	if strings.Contains(errStr, "duplicate entry") ||
		strings.Contains(errStr, "1062") || // MySQL error code for duplicate entry
		strings.Contains(errStr, "unique constraint") ||
		strings.Contains(errStr, "duplicate key") {
		return true
	}
	
	return false
}

func (r *gormRepository) GetByEmail(ctx context.Context, email string) (*User, error) {
	var u User
	err := r.db.WithContext(ctx).Where("email = ?", email).First(&u).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &u, nil
}

func (r *gormRepository) Delete(ctx context.Context, id string) error {
	return r.db.WithContext(ctx).Delete(&User{}, "id = ?", id).Error
}
