package router

import "github.com/gin-gonic/gin"

// setupAuthRoutes configures authentication routes
func (r *Router) setupAuthRoutes(api *gin.RouterGroup) {
	authRoutes := api.Group("/auth")
	{
		authRoutes.POST("/register", r.authHandler.Register)
		authRoutes.POST("/login", r.authHandler.Login)
		authRoutes.POST("/refresh", r.authHandler.RefreshToken)
		authRoutes.POST("/revoke", r.authHandler.RevokeToken)
	}
}

