package handlers

import (
	"fmt"
	"html/template"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"indekskos/internal/models"
	"indekskos/templates"

	"github.com/go-chi/chi/v5"
	"github.com/golang-jwt/jwt/v5"
	"github.com/jmoiron/sqlx"
	"golang.org/x/crypto/bcrypt"
)

type AdminHandler struct {
	DB *sqlx.DB
}

func (h *AdminHandler) LoginHandler(w http.ResponseWriter, r *http.Request) {
	tmpl, err := template.ParseFS(templates.FS, "layout/base.html", "admin/login.html")
	if err != nil {
		http.Error(w, "Template Error", http.StatusInternalServerError)
		return
	}
	hasError := r.URL.Query().Get("error") != ""
	data := map[string]interface{}{
		"Title": "Admin Login",
		"Error": hasError,
	}
	tmpl.ExecuteTemplate(w, "base.html", data)
}

func (h *AdminHandler) LoginPostHandler(w http.ResponseWriter, r *http.Request) {
	username := r.FormValue("username")
	password := r.FormValue("password")

	admin, err := models.GetAdminByUsername(h.DB, username)
	if err != nil {
		log.Printf("Login error: GetAdminByUsername failed for %s: %v", username, err)
		http.Redirect(w, r, "/admin/login?error=invalid", http.StatusSeeOther)
		return
	}

	err = bcrypt.CompareHashAndPassword([]byte(admin.PasswordHash), []byte(password))
	if err != nil {
		log.Printf("Login error: Password mismatch for %s", username)
		http.Redirect(w, r, "/admin/login?error=invalid", http.StatusSeeOther)
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
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}

	log.Printf("Login success: User %s logged in", username)

	isSecure := r.TLS != nil || r.Header.Get("X-Forwarded-Proto") == "https"
	http.SetCookie(w, &http.Cookie{
		Name:     "admin_session",
		Value:    tokenString,
		Path:     "/",
		HttpOnly: true,
		Secure:   isSecure,
		SameSite: http.SameSiteLaxMode,
	})

	http.Redirect(w, r, "/admin/dashboard", http.StatusSeeOther)
}

func (h *AdminHandler) LogoutHandler(w http.ResponseWriter, r *http.Request) {
	http.SetCookie(w, &http.Cookie{
		Name:     "admin_session",
		Value:    "",
		Path:     "/",
		HttpOnly: true,
		MaxAge:   -1,
	})
	http.Redirect(w, r, "/admin/login", http.StatusSeeOther)
}

func (h *AdminHandler) DashboardHandler(w http.ResponseWriter, r *http.Request) {
	stats, err := models.GetAdminDashboardStats(h.DB)
	if err != nil {
		stats = &models.DashboardStats{}
	}
	tmpl, err := template.ParseFS(templates.FS, "layout/admin_base.html", "admin/dashboard.html")
	if err != nil {
		http.Error(w, "Template Error", http.StatusInternalServerError)
		return
	}
	data := map[string]interface{}{"Title": "Dashboard", "Stats": stats}
	tmpl.ExecuteTemplate(w, "admin_base.html", data)
}

func (h *AdminHandler) ListingsHandler(w http.ResponseWriter, r *http.Request) {
	listings, _ := models.GetAllListingsAdmin(h.DB)
	tmpl, err := template.New("listings.html").Funcs(funcMap).ParseFS(templates.FS, "layout/admin_base.html", "admin/listings.html")
	if err != nil {
		http.Error(w, "Template Error", http.StatusInternalServerError)
		return
	}
	data := map[string]interface{}{"Title": "Manage Listings", "Listings": listings}
	tmpl.ExecuteTemplate(w, "admin_base.html", data)
}

func (h *AdminHandler) ToggleAvailabilityHandler(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(chi.URLParam(r, "id"))
	listing, err := models.GetListingByID(h.DB, id)
	if err != nil {
		http.Error(w, "Not found", http.StatusNotFound)
		return
	}
	newStatus := !listing.IsAvailable
	models.UpdateListingAvailability(h.DB, id, newStatus)
	
	class := "bg-red-100 text-red-800"
	text := "Full"
	if newStatus {
		class = "bg-green-100 text-green-800"
		text = "Available"
	}
	fmt.Fprintf(w, `<button hx-put="/admin/listings/%d/availability" hx-swap="outerHTML" class="px-3 py-1 rounded-full text-xs font-bold %s">%s</button>`, id, class, text)
}

func (h *AdminHandler) ToggleFeaturedHandler(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(chi.URLParam(r, "id"))
	listing, err := models.GetListingByID(h.DB, id)
	if err != nil {
		http.Error(w, "Not found", http.StatusNotFound)
		return
	}
	newStatus := !listing.IsFeatured
	models.UpdateListingFeatured(h.DB, id, newStatus)
	
	class := "bg-gray-100 text-gray-800"
	text := "Normal"
	if newStatus {
		class = "bg-yellow-100 text-yellow-800"
		text = "Featured"
	}
	fmt.Fprintf(w, `<button hx-put="/admin/listings/%d/featured" hx-swap="outerHTML" class="px-3 py-1 rounded-full text-xs font-bold %s">%s</button>`, id, class, text)
}

func (h *AdminHandler) UpdatePriceHandler(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(chi.URLParam(r, "id"))
	price, _ := strconv.Atoi(r.FormValue("price"))
	models.UpdateListingPrice(h.DB, id, price)
	w.WriteHeader(http.StatusOK)
}

func (h *AdminHandler) ReviewsHandler(w http.ResponseWriter, r *http.Request) {
	reviews, _ := models.GetAllReviewsAdmin(h.DB)
	tmpl, err := template.New("reviews.html").Funcs(funcMap).ParseFS(templates.FS, "layout/admin_base.html", "admin/reviews.html")
	if err != nil {
		http.Error(w, "Template Error", http.StatusInternalServerError)
		return
	}
	data := map[string]interface{}{"Title": "Manage Reviews", "Reviews": reviews}
	tmpl.ExecuteTemplate(w, "admin_base.html", data)
}

func (h *AdminHandler) ApproveReviewHandler(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(chi.URLParam(r, "id"))
	models.ApproveReview(h.DB, id)
	fmt.Fprint(w, `<span class="px-2 py-1 bg-green-100 text-green-800 text-xs rounded-full font-bold">Approved</span>`)
}

func (h *AdminHandler) DeleteReviewHandler(w http.ResponseWriter, r *http.Request) {
	id, _ := strconv.Atoi(chi.URLParam(r, "id"))
	models.DeleteReview(h.DB, id)
	w.WriteHeader(http.StatusOK)
}
