package models

import (
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/jmoiron/sqlx"
	"github.com/stretchr/testify/assert"
)

func TestGetAdminByUsername(t *testing.T) {
	db, mock, err := sqlmock.New()
	assert.NoError(t, err)
	defer db.Close()

	sqlxDB := sqlx.NewDb(db, "sqlmock")

	now := time.Now()
	rows := sqlmock.NewRows([]string{"id", "username", "password_hash", "created_at"}).
		AddRow(1, "admin", "hashedpassword", now)

	mock.ExpectQuery("^SELECT (.+) FROM admins WHERE username = \\$1").
		WithArgs("admin").
		WillReturnRows(rows)

	admin, err := GetAdminByUsername(sqlxDB, "admin")

	assert.NoError(t, err)
	assert.NotNil(t, admin)
	assert.Equal(t, "admin", admin.Username)
	assert.Equal(t, "hashedpassword", admin.PasswordHash)
}
