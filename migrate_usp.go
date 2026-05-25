package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"

	"github.com/joho/godotenv"
	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
)

func main() {
	godotenv.Load()
	dbURL := os.Getenv("DATABASE_URL")
	db, err := sqlx.Connect("postgres", dbURL)
	if err != nil {
		log.Fatalln(err)
	}

	content, err := ioutil.ReadFile("database/migrations/000003_add_usp_features.up.sql")
	if err != nil {
		log.Fatalln(err)
	}

	_, err = db.Exec(string(content))
	if err != nil {
		log.Fatalln("Migration failed:", err)
	}
	fmt.Println("Migration successful!")
}
