package main

import (
	"fmt"
	"go-rent/config"
	"go-rent/handlers"
	"go-rent/middleware"
	"go-rent/scheduler"
	"log"
	"net/http"
	"time"
	"github.com/gorilla/mux"
	"github.com/robfig/cron/v3"
)

func main() {
	// Initialize database connection
	err := config.InitDB()
	if err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}
	fmt.Println("Successfully connected to the database!")

	// Start scheduler
	go scheduler.StartScheduler()
	c := cron.New()
	// Run every minute for immediate test
	c.AddFunc("* * * * *", handlers.SendMonthlyNotifications)
	c.Start()

	// ✅ Use gorilla/mux router, not net/http ServeMux
	router := mux.NewRouter()

	// Apply CORS middleware to all routes
	router.Use(middleware.CORSMiddleware)
	
	// Apply rate limiting middleware to all routes
	router.Use(middleware.RateLimitMiddleware)

	// Public routes (no authentication required)
	router.HandleFunc("/login", handlers.LoginHandler).Methods("POST")
	router.HandleFunc("/register", handlers.RegisterHandler).Methods("POST")

	// Protected routes (authentication required)
	// Apply auth middleware to all protected routes
	protectedRouter := router.PathPrefix("/").Subrouter()
	protectedRouter.Use(middleware.AuthMiddleware)

	// Property routes
	protectedRouter.HandleFunc("/properties", handlers.GetUserPropertiesHandler).Methods("GET")
	protectedRouter.HandleFunc("/properties/tenant", handlers.GetUserTenantPropertiesHandler).Methods("GET")
	protectedRouter.HandleFunc("/property/{id:[0-9]+}", handlers.GetPropertyByIDHandler).Methods("GET")
	protectedRouter.HandleFunc("/property/{id:[0-9]+}/manager", handlers.CheckUserManagerHandler).Methods("GET")
	protectedRouter.HandleFunc("/property", handlers.AddPropertyHandler).Methods("POST")

	// Manager-only routes (require manager privileges)
	managerRouter := protectedRouter.PathPrefix("/property/{id:[0-9]+}").Subrouter()
	managerRouter.Use(middleware.ManagerMiddleware)
	
	managerRouter.HandleFunc("/floor", handlers.GetFloorsHandler).Methods("GET")
	managerRouter.HandleFunc("/floor", handlers.AddFloorHandler).Methods("POST")
	managerRouter.HandleFunc("/floor/{floor_id:[0-9]+}", handlers.GetFloorByIDHandler).Methods("GET")
	managerRouter.HandleFunc("/floor/{floor_id:[0-9]+}", handlers.UpdateFloorHandler).Methods("PUT")
	managerRouter.HandleFunc("/floor/{floor_id:[0-9]+}/request", handlers.SendTenantRequestHandler).Methods("POST")
	managerRouter.HandleFunc("/floor/{floor_id:[0-9]+}/tenant", handlers.AddTenantToFloorHandler).Methods("POST")
	managerRouter.HandleFunc("/floor/{floor_id:[0-9]+}/tenant", handlers.RemoveTenantHandler).Methods("DELETE")
	managerRouter.HandleFunc("/floor/{floor_id:[0-9]+}/payment", handlers.CreatePaymentHandler).Methods("POST")

	// User routes
	protectedRouter.HandleFunc("/users/phones", handlers.GetUserPhonesHandler).Methods("GET")
	protectedRouter.HandleFunc("/users/phones/{phone}", handlers.GetUserIDByPhoneHandler).Methods("GET")

	// Notification routes
	protectedRouter.HandleFunc("/notifications", handlers.GetUserNotificationsHandler).Methods("GET")
	protectedRouter.HandleFunc("/notifications/mark-read", handlers.MarkNotificationsAsReadHandler).Methods("POST")
	protectedRouter.HandleFunc("/notifications/delete/{id}", handlers.DeleteNotificationHandler).Methods("DELETE")
	protectedRouter.HandleFunc("/notifications/action", handlers.HandleTenantRequestAction).Methods("POST")

	// New payment notification route
	protectedRouter.HandleFunc("/property/{id:[0-9]+}/floor/{floor_id:[0-9]+}/payment-notification", handlers.SendPaymentNotificationHandler).Methods("POST")

	// Get pending payment notifications for a floor
	protectedRouter.HandleFunc("/property/{id:[0-9]+}/floor/{floor_id:[0-9]+}/pending-payments", handlers.GetPendingPaymentNotificationsHandler).Methods("GET")

	// Test endpoint to manually trigger notifications
	protectedRouter.HandleFunc("/test/notifications", handlers.TestSendNotificationsHandler).Methods("POST")

	router.Walk(func(route *mux.Route, r *mux.Router, ancestors []*mux.Route) error {
		path, _ := route.GetPathTemplate()
		methods, _ := route.GetMethods()
		fmt.Printf("Registered route: %s %v\n", path, methods)
		return nil
	})
	
	// Create server with timeouts
	server := &http.Server{
		Addr:         ":8080",
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	fmt.Println("Server starting on http://0.0.0.0:8080")
	log.Fatal(server.ListenAndServe())
}