package main

import (
	"fmt"
	"go-rent/config"
	"go-rent/handlers"
	"go-rent/scheduler"
	"log"
	"net/http"
	"time"
	"github.com/gorilla/mux"
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

	// ✅ Use gorilla/mux router, not net/http ServeMux
	router := mux.NewRouter()

	// Register routes properly using gorilla/mux
	router.HandleFunc("/login", handlers.LoginHandler).Methods("POST")
	router.HandleFunc("/register", handlers.RegisterHandler).Methods("POST")

	// Property routes
	router.HandleFunc("/properties", handlers.GetUserPropertiesHandler).Methods("GET")
	router.HandleFunc("/properties/tenant", handlers.GetUserTenantPropertiesHandler).Methods("GET")
	router.HandleFunc("/property", handlers.AddPropertyHandler).Methods("POST")
	router.HandleFunc("/property/{id:[0-9]+}", handlers.GetPropertyByIDHandler).Methods("GET")
	router.HandleFunc("/property/{id:[0-9]+}/manager", handlers.CheckUserManagerHandler).Methods("GET")

	// Floor routes
	router.HandleFunc("/property/{id:[0-9]+}/floor", handlers.AddFloorHandler).Methods("POST")
	router.HandleFunc("/property/{id:[0-9]+}/floor", handlers.GetFloorsHandler).Methods("GET")

	// Floor details and update routes
	router.HandleFunc("/property/{id:[0-9]+}/floor/{floor_id:[0-9]+}", func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodGet {
			handlers.GetFloorByIDHandler(w, r)
		} else if r.Method == http.MethodPut {
			handlers.UpdateFloorHandler(w, r)
		} else {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	}).Methods("GET", "PUT")

	// Tenant request route
	router.HandleFunc("/property/{id:[0-9]+}/floor/{floor_id:[0-9]+}/request", handlers.SendTenantRequestHandler).Methods("POST")

	// Payment route
	router.HandleFunc("/property/{id:[0-9]+}/floor/{floor_id:[0-9]+}/payment", handlers.CreatePaymentHandler).Methods("POST")

	// User phones route
	router.HandleFunc("/users/phones", handlers.GetUserPhonesHandler).Methods("GET")
	router.HandleFunc("/users/phones/{phone}", handlers.GetUserIDByPhoneHandler).Methods("GET")

	router.HandleFunc("/notifications", handlers.GetUserNotificationsHandler).Methods("GET")
	router.HandleFunc("/notifications/delete/{id}", handlers.DeleteNotificationHandler).Methods("DELETE")
	router.HandleFunc("/notifications/action", handlers.HandleTenantRequestAction).Methods("POST")

	// Add this route to support DELETE /property/{id}/floor/{floor_id}/tenant
	router.HandleFunc("/property/{id:[0-9]+}/floor/{floor_id:[0-9]+}/tenant", handlers.RemoveTenantHandler).Methods("DELETE")

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