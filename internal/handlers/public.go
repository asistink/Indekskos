package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"

	"indekskos/internal/models"

	"github.com/go-chi/chi/v5"
	"github.com/jmoiron/sqlx"
)

type PublicHandler struct {
	DB *sqlx.DB
}

func respondJSON(w http.ResponseWriter, status int, payload interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(payload)
}

func respondError(w http.ResponseWriter, status int, message string) {
	respondJSON(w, status, map[string]string{"error": message})
}

// HomeHandler returns featured listings, nearby listings, and distinct areas for the home screen.
func (h *PublicHandler) HomeHandler(w http.ResponseWriter, r *http.Request) {
	featured, _ := models.GetFeaturedListings(h.DB)
	nearby, _ := models.GetNearbyListings(h.DB)
	areas, _ := models.GetDistinctAreas(h.DB)

	if featured == nil {
		featured = []models.Listing{}
	}
	if nearby == nil {
		nearby = []models.Listing{}
	}
	if areas == nil {
		areas = []string{}
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"featured": featured,
		"nearby":   nearby,
		"areas":    areas,
	})
}

// SearchHandler handles search with filters: q, min_price, max_price, kos_type, facilities.
func (h *PublicHandler) SearchHandler(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query().Get("q")
	minPrice, _ := strconv.Atoi(r.URL.Query().Get("min_price"))
	maxPrice, _ := strconv.Atoi(r.URL.Query().Get("max_price"))

	var kosTypes []string
	if kt := r.URL.Query().Get("kos_type"); kt != "" {
		kosTypes = strings.Split(kt, ",")
	}

	var facilities []string
	if fac := r.URL.Query().Get("facilities"); fac != "" {
		facilities = strings.Split(fac, ",")
	}

	listings, err := models.SearchListings(h.DB, query, minPrice, maxPrice, kosTypes, facilities)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Database error")
		return
	}

	if listings == nil {
		listings = []models.Listing{}
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"data": listings,
	})
}

// DetailHandler returns a listing with its approved reviews.
func (h *PublicHandler) DetailHandler(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "Invalid ID")
		return
	}

	listing, err := models.GetListingByID(h.DB, id)
	if err != nil {
		respondError(w, http.StatusNotFound, "Listing not found")
		return
	}

	reviews, _ := models.GetApprovedReviewsByListingID(h.DB, id)
	if reviews == nil {
		reviews = []models.Review{}
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"data":    listing,
		"reviews": reviews,
	})
}

// GetReviewsHandler returns approved reviews for a listing.
func (h *PublicHandler) GetReviewsHandler(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "Invalid ID")
		return
	}

	reviews, err := models.GetApprovedReviewsByListingID(h.DB, id)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Database error")
		return
	}
	if reviews == nil {
		reviews = []models.Review{}
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{"data": reviews})
}

// PostReviewHandler creates a new review (pending approval).
func (h *PublicHandler) PostReviewHandler(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(chi.URLParam(r, "id"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "Invalid ID")
		return
	}

	var req struct {
		ReviewerName  string  `json:"reviewer_name"`
		ReviewerEmail *string `json:"reviewer_email"`
		Rating        int     `json:"rating"`
		Comment       *string `json:"comment"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if req.ReviewerName == "" || req.Rating < 1 || req.Rating > 5 {
		respondError(w, http.StatusBadRequest, "Name and valid rating (1-5) are required")
		return
	}

	review := &models.Review{
		ListingID:     id,
		ReviewerName:  req.ReviewerName,
		ReviewerEmail: req.ReviewerEmail,
		Rating:        req.Rating,
		Comment:       req.Comment,
	}

	if err := models.CreateReview(h.DB, review); err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to create review")
		return
	}

	respondJSON(w, http.StatusCreated, map[string]interface{}{
		"message": "Review submitted successfully. Awaiting approval.",
	})
}

// ConfirmAvailabilityHandler updates last_confirmed_at using a secret token
func (h *PublicHandler) ConfirmAvailabilityHandler(w http.ResponseWriter, r *http.Request) {
	token := r.URL.Query().Get("token")
	if token == "" {
		respondError(w, http.StatusBadRequest, "Token is required")
		return
	}

	err := models.ConfirmAvailability(h.DB, token)
	if err != nil {
		respondError(w, http.StatusBadRequest, "Invalid or expired token")
		return
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"message": "Availability confirmed successfully",
	})
}
