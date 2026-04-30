package models

import (
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/jmoiron/sqlx"
	"github.com/stretchr/testify/assert"
)

func TestGetListingByID(t *testing.T) {
	db, mock, err := sqlmock.New()
	assert.NoError(t, err)
	defer db.Close()

	sqlxDB := sqlx.NewDb(db, "sqlmock")

	now := time.Now()
	rows := sqlmock.NewRows([]string{"id", "name", "area", "address", "price_per_month", "landlord_wa_number", "created_at", "updated_at"}).
		AddRow(1, "Kos A", "Sleman", "Jl. Kaliurang", 1000000, "08123", now, now)

	mock.ExpectQuery("^SELECT \\* FROM listings WHERE id = \\$1").
		WithArgs(1).
		WillReturnRows(rows)

	listing, err := GetListingByID(sqlxDB, 1)

	assert.NoError(t, err)
	assert.NotNil(t, listing)
	assert.Equal(t, "Kos A", listing.Name)
	assert.Equal(t, 1000000, listing.PricePerMonth)
}
