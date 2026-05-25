package handlers

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"indekskos/internal/models"

	"fmt"
	"io"
	"path/filepath"

	"github.com/go-chi/chi/v5"
	"github.com/golang-jwt/jwt/v5"
	"github.com/jmoiron/sqlx"
	"golang.org/x/crypto/bcrypt"
)

type AdminHandler struct {
	DB *sqlx.DB
}

func (h *AdminHandler) LoginPostHandler(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Username string `json:"username"`
		Password string `json:"password"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	admin, err := models.GetAdminByUsername(h.DB, req.Username)
	if err != nil {
		log.Printf("Login error: GetAdminByUsername failed for %s: %v", req.Username, err)
		respondError(w, http.StatusUnauthorized, "Invalid credentials")
		return
	}

	err = bcrypt.CompareHashAndPassword([]byte(admin.PasswordHash), []byte(req.Password))
	if err != nil {
		log.Printf("Login error: Password mismatch for %s", req.Username)
		respondError(w, http.StatusUnauthorized, "Invalid credentials")
		return
	}

	// Create JWT token
	secret := os.Getenv("JWT_SECRET")
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"username": admin.Username,
		"exp":      time.Now().Add(24 * time.Hour).Unix(),
	})
	tokenString, err := token.SignedString([]byte(secret))
	if err != nil {
		log.Printf("Login error: Failed to sign token: %v", err)
		respondError(w, http.StatusInternalServerError, "Internal Server Error")
		return
	}

	log.Printf("Login success: User %s logged in", req.Username)

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"message": "Login successful",
		"token":   tokenString,
	})
}

func (h *AdminHandler) DashboardHandler(w http.ResponseWriter, r *http.Request) {
	stats, err := models.GetAdminDashboardStats(h.DB)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to get stats")
		return
	}
	respondJSON(w, http.StatusOK, map[string]interface{}{"data": stats})
}

func (h *AdminHandler) ListingsHandler(w http.ResponseWriter, r *http.Request) {
	listings, err := models.GetAllListingsAdmin(h.DB)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to get listings")
		return
	}
	if listings == nil {
		listings = []models.Listing{}
	}
	respondJSON(w, http.StatusOK, map[string]interface{}{"data": listings})
}

func (h *AdminHandler) ToggleAvailabilityHandler(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(chi.URLParam(r, "id"))
	listing, err := models.GetListingByID(h.DB, id)
	if err != nil {
		respondError(w, http.StatusNotFound, "Listing not found")
		return
	}
	newStatus := !listing.IsAvailable
	err = models.UpdateListingAvailability(h.DB, id, newStatus)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to update")
		return
	}
	respondJSON(w, http.StatusOK, map[string]interface{}{"success": true, "is_available": newStatus})
}

func (h *AdminHandler) ToggleFeaturedHandler(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(chi.URLParam(r, "id"))
	listing, err := models.GetListingByID(h.DB, id)
	if err != nil {
		respondError(w, http.StatusNotFound, "Listing not found")
		return
	}
	newStatus := !listing.IsFeatured
	err = models.UpdateListingFeatured(h.DB, id, newStatus)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to update")
		return
	}
	respondJSON(w, http.StatusOK, map[string]interface{}{"success": true, "is_featured": newStatus})
}

func (h *AdminHandler) UpdatePriceHandler(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(chi.URLParam(r, "id"))
	var req struct {
		Price int `json:"price"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	err := models.UpdateListingPrice(h.DB, id, req.Price)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to update")
		return
	}
	respondJSON(w, http.StatusOK, map[string]interface{}{"success": true})
}

func (h *AdminHandler) ReviewsHandler(w http.ResponseWriter, r *http.Request) {
	reviews, err := models.GetAllReviewsAdmin(h.DB)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to get reviews")
		return
	}
	if reviews == nil {
		reviews = []models.Review{}
	}
	respondJSON(w, http.StatusOK, map[string]interface{}{"data": reviews})
}

func (h *AdminHandler) ApproveReviewHandler(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(chi.URLParam(r, "id"))
	err := models.ApproveReview(h.DB, id)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to approve")
		return
	}
	respondJSON(w, http.StatusOK, map[string]interface{}{"success": true})
}

func (h *AdminHandler) DeleteReviewHandler(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(chi.URLParam(r, "id"))
	err := models.DeleteReview(h.DB, id)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to delete")
		return
	}
	respondJSON(w, http.StatusOK, map[string]interface{}{"success": true})
}

func (h *AdminHandler) UploadVideoHandler(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(chi.URLParam(r, "id"))

	// Parse multipart form
	err := r.ParseMultipartForm(50 << 20) // 50MB max memory
	if err != nil {
		respondError(w, http.StatusBadRequest, "File too large or invalid request")
		return
	}

	file, handler, err := r.FormFile("video")
	if err != nil {
		respondError(w, http.StatusBadRequest, "No video file found")
		return
	}
	defer file.Close()

	// Ensure uploads directory exists
	os.MkdirAll("uploads", os.ModePerm)

	// Save file locally
	filename := fmt.Sprintf("kos_%d_%d%s", id, time.Now().Unix(), filepath.Ext(handler.Filename))
	dstPath := filepath.Join("uploads", filename)

	dst, err := os.Create(dstPath)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to save file")
		return
	}
	defer dst.Close()

	if _, err := io.Copy(dst, file); err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to write file")
		return
	}

	// Build public URL (assuming local /uploads endpoint)
	videoURL := fmt.Sprintf("/uploads/%s", filename)

	err = models.UpdateListingVideo(h.DB, id, videoURL)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to update database")
		return
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"success":   true,
		"video_url": videoURL,
	})
}
