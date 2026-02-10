package database

import (
	"fmt"
	"time"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"

	"werk-ticketing/internal/config"
	"werk-ticketing/internal/constants"
)

// Connect opens a Gorm MySQL connection with sane defaults.
func Connect(cfg *config.Config) (*gorm.DB, error) {
	var dsn string
	if cfg.DBPass == "" {
		// DSN format without password for MySQL without password
		dsn = fmt.Sprintf("%s@tcp(%s:%s)/%s?parseTime=true&charset=utf8mb4&loc=UTC",
			cfg.DBUser,
			cfg.DBHost,
			cfg.DBPort,
			cfg.DBName,
		)
	} else {
		// DSN format with password
		dsn = fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?parseTime=true&charset=utf8mb4&loc=UTC",
			cfg.DBUser,
			cfg.DBPass,
			cfg.DBHost,
			cfg.DBPort,
			cfg.DBName,
		)
	}

	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Warn),
	})
	if err != nil {
		return nil, err
	}

	sqlDB, err := db.DB()
	if err != nil {
		return nil, err
	}

	sqlDB.SetConnMaxLifetime(time.Duration(constants.DBConnMaxLifetime) * time.Minute)
	sqlDB.SetConnMaxIdleTime(time.Duration(constants.DBConnMaxIdleTime) * time.Minute)
	sqlDB.SetMaxOpenConns(constants.DBMaxOpenConns)
	sqlDB.SetMaxIdleConns(constants.DBMaxIdleConns)

	return db, nil
}
