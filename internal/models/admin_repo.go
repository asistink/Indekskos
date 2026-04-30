package models

import "github.com/jmoiron/sqlx"

func GetAdminByUsername(db *sqlx.DB, username string) (*Admin, error) {
	var admin Admin
	err := db.Get(&admin, "SELECT * FROM admins WHERE username = $1", username)
	if err != nil {
		return nil, err
	}
	return &admin, nil
}

type DashboardStats struct {
	TotalListings  int `db:"total_listings"`
	ActiveListings int `db:"active_listings"`
	PendingReviews int `db:"pending_reviews"`
}

func GetAdminDashboardStats(db *sqlx.DB) (*DashboardStats, error) {
	var stats DashboardStats
	query := `
		SELECT 
			(SELECT COUNT(*) FROM listings) AS total_listings,
			(SELECT COUNT(*) FROM listings WHERE is_available = true) AS active_listings,
			(SELECT COUNT(*) FROM reviews WHERE is_approved = false) AS pending_reviews
	`
	err := db.Get(&stats, query)
	if err != nil {
		return nil, err
	}
	return &stats, nil
}
