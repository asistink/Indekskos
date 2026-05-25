package models

import (
	"fmt"
	"strings"

	"github.com/jmoiron/sqlx"
)

func GetListingByID(db *sqlx.DB, id int) (*Listing, error) {
	var listing Listing
	err := db.Get(&listing, "SELECT * FROM listings WHERE id = $1", id)
	if err != nil {
		return nil, err
	}
	return &listing, nil
}

// SearchListings supports query, price range, kos_type filter, and facility filter.
func SearchListings(db *sqlx.DB, query string, minPrice, maxPrice int, kosTypes []string, facilities []string) ([]Listing, error) {
	var listings []Listing
	searchQ := "%" + query + "%"

	sqlStr := "SELECT * FROM listings WHERE (name ILIKE $1 OR area ILIKE $1 OR university_nearby ILIKE $1 OR target_campus ILIKE $1)"
	args := []interface{}{searchQ}
	argID := 2

	if minPrice > 0 {
		sqlStr += fmt.Sprintf(" AND price_per_month >= $%d", argID)
		args = append(args, minPrice)
		argID++
	}
	if maxPrice > 0 {
		sqlStr += fmt.Sprintf(" AND price_per_month <= $%d", argID)
		args = append(args, maxPrice)
		argID++
	}

	// Filter by kos_type (e.g. ["putra","campur"])
	if len(kosTypes) > 0 {
		placeholders := make([]string, len(kosTypes))
		for i, kt := range kosTypes {
			placeholders[i] = fmt.Sprintf("$%d", argID)
			args = append(args, kt)
			argID++
		}
		sqlStr += " AND kos_type IN (" + strings.Join(placeholders, ",") + ")"
	}

	// Filter by facilities (all selected facilities must exist in the listing)
	for _, fac := range facilities {
		sqlStr += fmt.Sprintf(" AND $%d = ANY(facilities)", argID)
		args = append(args, fac)
		argID++
	}

	// USP Ghosting-Free: prioritize listings confirmed within the last 3 days
	// They will be sorted first, followed by featured, then by created_at
	sqlStr += " ORDER BY CASE WHEN last_confirmed_at >= NOW() - INTERVAL '3 days' THEN 1 ELSE 0 END DESC, is_featured DESC, created_at DESC LIMIT 50"

	err := db.Select(&listings, sqlStr, args...)
	return listings, err
}

// GetFeaturedListings returns listings marked as featured.
func GetFeaturedListings(db *sqlx.DB) ([]Listing, error) {
	var listings []Listing
	err := db.Select(&listings, "SELECT * FROM listings WHERE is_featured = true ORDER BY created_at DESC LIMIT 10")
	return listings, err
}

// GetNearbyListings returns listings in any area, ordered by rating.
func GetNearbyListings(db *sqlx.DB) ([]Listing, error) {
	var listings []Listing
	err := db.Select(&listings, "SELECT * FROM listings WHERE is_available = true ORDER BY average_rating DESC LIMIT 20")
	return listings, err
}

// GetDistinctAreas returns unique area names.
func GetDistinctAreas(db *sqlx.DB) ([]string, error) {
	var areas []string
	err := db.Select(&areas, "SELECT DISTINCT area FROM listings ORDER BY area")
	return areas, err
}

func GetAllListingsAdmin(db *sqlx.DB) ([]Listing, error) {
	var listings []Listing
	err := db.Select(&listings, "SELECT * FROM listings ORDER BY created_at DESC")
	return listings, err
}

func UpdateListingAvailability(db *sqlx.DB, id int, isAvailable bool) error {
	_, err := db.Exec("UPDATE listings SET is_available = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2", isAvailable, id)
	return err
}

func UpdateListingFeatured(db *sqlx.DB, id int, isFeatured bool) error {
	_, err := db.Exec("UPDATE listings SET is_featured = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2", isFeatured, id)
	return err
}

func UpdateListingPrice(db *sqlx.DB, id int, price int) error {
	_, err := db.Exec("UPDATE listings SET price_per_month = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2", price, id)
	return err
}

func ConfirmAvailability(db *sqlx.DB, token string) error {
	res, err := db.Exec("UPDATE listings SET last_confirmed_at = CURRENT_TIMESTAMP WHERE confirmation_token = $1", token)
	if err != nil {
		return err
	}
	rowsAffected, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if rowsAffected == 0 {
		return fmt.Errorf("invalid token or listing not found")
	}
	return nil
}
