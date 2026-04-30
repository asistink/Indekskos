package models

import "github.com/jmoiron/sqlx"

func GetAllReviewsAdmin(db *sqlx.DB) ([]Review, error) {
	var reviews []Review
	err := db.Select(&reviews, "SELECT * FROM reviews ORDER BY is_approved ASC, created_at DESC")
	return reviews, err
}

func ApproveReview(db *sqlx.DB, id int) error {
	_, err := db.Exec("UPDATE reviews SET is_approved = true WHERE id = $1", id)
	return err
}

func DeleteReview(db *sqlx.DB, id int) error {
	_, err := db.Exec("DELETE FROM reviews WHERE id = $1", id)
	return err
}
