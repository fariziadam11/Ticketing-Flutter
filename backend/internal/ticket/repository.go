package ticket

import (
	"context"
	"errors"

	"gorm.io/gorm"
)

// Repository abstracts data persistence for tickets.
type Repository interface {
	Create(ctx context.Context, ticket *Ticket) error
	GetByInvGateID(ctx context.Context, invGateID string) (*Ticket, error)
	GetByCreatorEmail(ctx context.Context, creatorEmail string) ([]*Ticket, error)
	GetByCreatorEmailPaginated(ctx context.Context, creatorEmail string, limit, offset int) ([]*Ticket, error)
	CountByCreatorEmail(ctx context.Context, creatorEmail string) (int64, error)
	GetByID(ctx context.Context, id string) (*Ticket, error)
}

type gormRepository struct {
	db *gorm.DB
}

// NewRepository builds a Gorm-backed ticket repository.
func NewRepository(db *gorm.DB) Repository {
	return &gormRepository{db: db}
}

func (r *gormRepository) Create(ctx context.Context, ticket *Ticket) error {
	return r.db.WithContext(ctx).Create(ticket).Error
}

func (r *gormRepository) GetByInvGateID(ctx context.Context, invGateID string) (*Ticket, error) {
	var t Ticket
	err := r.db.WithContext(ctx).Where("inv_gate_id = ?", invGateID).First(&t).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &t, nil
}

func (r *gormRepository) GetByCreatorEmail(ctx context.Context, creatorEmail string) ([]*Ticket, error) {
	var tickets []*Ticket
	// Order by created_at DESC to show newest tickets first
	// Note: This makes tickets with newer inv_gate_id appear first because
	// newer tickets typically have both newer created_at and higher inv_gate_id
	query := r.db.WithContext(ctx).Order("created_at DESC")
	if creatorEmail != "" {
		query = query.Where("creator_email = ?", creatorEmail)
	}

	err := query.Find(&tickets).Error
	if err != nil {
		return nil, err
	}
	return tickets, nil
}

// GetByCreatorEmailPaginated retrieves tickets by creator email with pagination support.
func (r *gormRepository) GetByCreatorEmailPaginated(ctx context.Context, creatorEmail string, limit, offset int) ([]*Ticket, error) {
	var tickets []*Ticket
	query := r.db.WithContext(ctx).Order("created_at DESC")
	if creatorEmail != "" {
		query = query.Where("creator_email = ?", creatorEmail)
	}

	err := query.Limit(limit).Offset(offset).Find(&tickets).Error
	if err != nil {
		return nil, err
	}
	return tickets, nil
}

// CountByCreatorEmail counts total tickets by creator email.
func (r *gormRepository) CountByCreatorEmail(ctx context.Context, creatorEmail string) (int64, error) {
	var count int64
	query := r.db.WithContext(ctx).Model(&Ticket{})
	if creatorEmail != "" {
		query = query.Where("creator_email = ?", creatorEmail)
	}

	err := query.Count(&count).Error
	if err != nil {
		return 0, err
	}
	return count, nil
}

func (r *gormRepository) GetByID(ctx context.Context, id string) (*Ticket, error) {
	var t Ticket
	err := r.db.WithContext(ctx).Where("id = ?", id).First(&t).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &t, nil
}
