package handlers

import (
	"html/template"
	"net/http"
	"strconv"

	"indekskos/internal/models"
	"indekskos/templates"

	"github.com/jmoiron/sqlx"
)

type PublicHandler struct {
	DB *sqlx.DB
}

var funcMap = template.FuncMap{
	"formatRupiah": func(amount int) string {
		s := strconv.Itoa(amount)
		n := len(s)
		if n <= 3 {
			return s
		}
		var res string
		for i, c := range s {
			if i > 0 && (n-i)%3 == 0 {
				res += "."
			}
			res += string(c)
		}
		return res
	},
	"isValidImage": func(url *string) bool {
		return url != nil && *url != ""
	},
}

func (h *PublicHandler) HomeHandler(w http.ResponseWriter, r *http.Request) {
	tmpl, err := template.New("base.html").Funcs(funcMap).ParseFS(templates.FS, "layout/base.html", "public/home.html")
	if err != nil {
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}

	data := map[string]interface{}{
		"Title": "Beranda",
	}

	tmpl.ExecuteTemplate(w, "base.html", data)
}

func (h *PublicHandler) SearchHandler(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query().Get("q")
	
	minPriceStr := r.URL.Query().Get("min_price")
	maxPriceStr := r.URL.Query().Get("max_price")
	
	minPrice, _ := strconv.Atoi(minPriceStr)
	maxPrice, _ := strconv.Atoi(maxPriceStr)

	listings, err := models.SearchListings(h.DB, query, minPrice, maxPrice)
	if err != nil {
		http.Error(w, "Database error", http.StatusInternalServerError)
		return
	}

	tmpl, err := template.New("search_results.html").Funcs(funcMap).ParseFS(templates.FS, "public/search_results.html")
	if err != nil {
		http.Error(w, "Template error", http.StatusInternalServerError)
		return
	}

	data := map[string]interface{}{
		"Listings": listings,
	}
	tmpl.Execute(w, data)
}
