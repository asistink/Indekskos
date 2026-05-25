package models

import "github.com/jmoiron/sqlx"

func GetAllReviewsAdmin(db *sqlx.DB) ([]Review, error) {
	var reviews []Review
	err := db.Select(&reviews, "SELECT * FROM reviews ORDER BY is_approved ASC, created_at DESC")
	return reviews, err
}

func GetApprovedReviewsByListingID(db *sqlx.DB, listingID int) ([]Review, error) {
	var reviews []Review
	err := db.Select(&reviews, "SELECT * FROM reviews WHERE listing_id = $1 AND is_approved = true ORDER BY created_at DESC", listingID)
	return reviews, err
}

func CreateReview(db *sqlx.DB, review *Review) error {
	_, err := db.Exec(
		"INSERT INTO reviews (listing_id, reviewer_name, reviewer_email, rating, comment, is_approved) VALUES ($1, $2, $3, $4, $5, false)",
		review.ListingID, review.ReviewerName, review.ReviewerEmail, review.Rating, review.Comment,
	)
	return err
}

func ApproveReview(db *sqlx.DB, id int) error {
	_, err := db.Exec("UPDATE reviews SET is_approved = true WHERE id = $1", id)
	return err
}

func DeleteReview(db *sqlx.DB, id int) error {
	_, err := db.Exec("DELETE FROM reviews WHERE id = $1", id)
	return err
}
