package middlewares

import (
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/stretchr/testify/assert"
)

func TestRequireAdmin(t *testing.T) {
	os.Setenv("JWT_SECRET", "test_secret")

	// Create valid token
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"username": "admin",
		"exp":      time.Now().Add(time.Hour).Unix(),
	})
	tokenString, _ := token.SignedString([]byte("test_secret"))

	req, err := http.NewRequest("GET", "/admin/dashboard", nil)
	assert.NoError(t, err)

	// Add cookie
	req.AddCookie(&http.Cookie{
		Name:  "admin_session",
		Value: tokenString,
	})

	rr := httptest.NewRecorder()
	
	// Test handler
	testHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	handler := RequireAdmin(testHandler)
	handler.ServeHTTP(rr, req)

	assert.Equal(t, http.StatusOK, rr.Code)
}

func TestRequireAdmin_NoCookie(t *testing.T) {
	req, err := http.NewRequest("GET", "/admin/dashboard", nil)
	assert.NoError(t, err)

	rr := httptest.NewRecorder()
	testHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {})

	handler := RequireAdmin(testHandler)
	handler.ServeHTTP(rr, req)

	assert.Equal(t, http.StatusSeeOther, rr.Code)
}
