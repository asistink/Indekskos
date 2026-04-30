package models

import (
	"fmt"

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

func SearchListings(db *sqlx.DB, query string, minPrice, maxPrice int) ([]Listing, error) {
	var listings []Listing
	searchQ := "%" + query + "%"

	sqlStr := "SELECT * FROM listings WHERE (name ILIKE $1 OR area ILIKE $1 OR university_nearby ILIKE $1)"
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

	sqlStr += " ORDER BY is_featured DESC, created_at DESC LIMIT 50"

	err := db.Select(&listings, sqlStr, args...)
	return listings, err
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
