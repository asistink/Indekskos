package models

import "time"

type Review struct {
	ID            int       `db:"id" json:"id"`
	ListingID     int       `db:"listing_id" json:"listing_id"`
	ReviewerName  string    `db:"reviewer_name" json:"reviewer_name"`
	ReviewerEmail *string   `db:"reviewer_email" json:"reviewer_email"`
	Rating        int       `db:"rating" json:"rating"`
	Comment       *string   `db:"comment" json:"comment"`
	IsApproved    bool      `db:"is_approved" json:"is_approved"`
	CreatedAt     time.Time `db:"created_at" json:"created_at"`
}
