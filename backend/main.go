package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/sirupsen/logrus"

	"werk-ticketing/internal/auth"
	"werk-ticketing/internal/config"
	"werk-ticketing/internal/constants"
	"werk-ticketing/internal/database"
	"werk-ticketing/internal/invgate"
	"werk-ticketing/internal/router"
	"werk-ticketing/internal/ticket"
	"werk-ticketing/internal/user"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("config error: %v", err)
	}

	db, err := database.Connect(cfg)
	if err != nil {
		log.Fatalf("database error: %v", err)
	}
	sqlDB, err := db.DB()
	if err != nil {
		log.Fatalf("database pooling error: %v", err)
	}
	defer sqlDB.Close()

	// Auto migrate all models
	// This ensures all tables are created/updated when the application starts
	if err := db.AutoMigrate(
		&user.User{},     // Users table
		&ticket.Ticket{}, // Tickets table
	); err != nil {
		log.Fatalf("auto migrate error: %v", err)
	}

	logger := logrus.New()
	logger.SetFormatter(&logrus.TextFormatter{
		FullTimestamp:   true,
		ForceColors:     true,
		DisableQuote:    true,
		TimestampFormat: time.RFC3339,
	})
	logger.SetLevel(logrus.InfoLevel)

	// Initialize services
	invgateClient := invgate.NewService(cfg)
	userRepo := user.NewRepository(db)
	ticketRepo := ticket.NewRepository(db)
	ticketService := ticket.NewService(invgateClient, ticketRepo, userRepo, logger)
	ticketHandler := ticket.NewHandler(ticketService)

	authService := auth.NewService(
		userRepo,
		invgateClient,
		cfg.JWTSecret,
		logger,
		cfg.ArmMadaCompanyID,
		cfg.ArmMadaGroupID,
		cfg.ArmMadaLocationID,
	)
	authHandler := auth.NewHandler(authService)

	// Setup router
	appRouter := router.NewRouter(authHandler, ticketHandler, authService, logger)
	ginRouter := appRouter.SetupRoutes()

	// Create HTTP server
	addr := ":" + cfg.ServerPort
	srv := &http.Server{
		Addr:    addr,
		Handler: ginRouter,
	}

	// Start server in a goroutine
	go func() {
		logger.Infof("backend server listening on %s", addr)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatalf("server error: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	// SIGINT (Ctrl+C) and SIGTERM (kill command)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	logger.Info("shutting down server...")

	// The context is used to inform the server it has 30 seconds to finish
	// the request it is currently handling
	ctx, cancel := context.WithTimeout(context.Background(), constants.GracefulShutdownTimeout)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		logger.Fatalf("server forced to shutdown: %v", err)
	}

	logger.Info("server exited")
}
