package main

import (
	"log"
	"net/http"
	"os"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/jmoiron/sqlx"
	"github.com/joho/godotenv"

	"indekskos/internal/handlers"
	"indekskos/internal/middlewares"
)

func main() {
	_ = godotenv.Load()

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		dbURL = "postgres://postgres:postgres@localhost:5432/indekskos?sslmode=disable"
	}

	db, err := sqlx.Connect("pgx", dbURL)
	if err != nil {
		log.Printf("Warning: failed to connect to database: %v", err)
	} else {
		defer db.Close()
		log.Println("Connected to database")
	}

	r := chi.NewRouter()
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)

	publicHandler := &handlers.PublicHandler{DB: db}
	r.Get("/", publicHandler.HomeHandler)
	r.Get("/search", publicHandler.SearchHandler)

	adminHandler := &handlers.AdminHandler{DB: db}
	r.Route("/admin", func(r chi.Router) {
		r.Get("/login", adminHandler.LoginHandler)
		r.Post("/login", adminHandler.LoginPostHandler)
		r.Get("/logout", adminHandler.LogoutHandler)

		r.Group(func(r chi.Router) {
			r.Use(middlewares.RequireAdmin)
			r.Get("/dashboard", adminHandler.DashboardHandler)
			r.Get("/listings", adminHandler.ListingsHandler)
			r.Put("/listings/{id}/availability", adminHandler.ToggleAvailabilityHandler)
			r.Put("/listings/{id}/featured", adminHandler.ToggleFeaturedHandler)
			r.Put("/listings/{id}/price", adminHandler.UpdatePriceHandler)
			r.Get("/reviews", adminHandler.ReviewsHandler)
			r.Put("/reviews/{id}/approve", adminHandler.ApproveReviewHandler)
			r.Delete("/reviews/{id}", adminHandler.DeleteReviewHandler)
		})
	})

	// Additional routes would go here
	// r.Get("/kos/{id}", handlers.DetailHandler(db))

	log.Printf("Starting server on port %s", port)
	if err := http.ListenAndServe(":"+port, r); err != nil {
		log.Fatal(err)
	}
}
