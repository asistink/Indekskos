package models

import (
	"time"

	"github.com/lib/pq"
)

type Listing struct {
	ID                   int            `db:"id" json:"id"`
	Name                 string         `db:"name" json:"name"`
	Area                 string         `db:"area" json:"area"`
	Address              string         `db:"address" json:"address"`
	UniversityNearby     *string        `db:"university_nearby" json:"university_nearby"`
	PricePerMonth        int            `db:"price_per_month" json:"price_per_month"`
	Description          *string        `db:"description" json:"description"`
	ThumbnailURL         *string        `db:"thumbnail_url" json:"thumbnail_url"`
	PhotoURLs            pq.StringArray `db:"photo_urls" json:"photo_urls"`
	Facilities           pq.StringArray `db:"facilities" json:"facilities"`
	IsAvailable          bool           `db:"is_available" json:"is_available"`
	LandlordWANumber     string         `db:"landlord_wa_number" json:"landlord_wa_number"`
	IsFeatured           bool           `db:"is_featured" json:"is_featured"`
	AverageRating        float64        `db:"average_rating" json:"average_rating"`
	GoogleMapsIframeURL  *string        `db:"google_maps_iframe_url" json:"google_maps_iframe_url"`
	CreatedAt            time.Time      `db:"created_at" json:"created_at"`
	UpdatedAt            time.Time      `db:"updated_at" json:"updated_at"`
}
