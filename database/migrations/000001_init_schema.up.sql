CREATE TABLE admins (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE listings (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    area VARCHAR(255) NOT NULL, 
    address TEXT NOT NULL,
    university_nearby VARCHAR(255), 
    price_per_month INTEGER NOT NULL,
    description TEXT,
    thumbnail_url TEXT,
    photo_urls TEXT[], 
    facilities TEXT[], 
    is_available BOOLEAN DEFAULT TRUE,
    landlord_wa_number VARCHAR(20) NOT NULL, 
    is_featured BOOLEAN DEFAULT FALSE,
    average_rating DECIMAL(2,1) DEFAULT 0,
    google_maps_iframe_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    listing_id INTEGER REFERENCES listings(id) ON DELETE CASCADE,
    reviewer_name VARCHAR(255) NOT NULL,
    reviewer_email VARCHAR(255),
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    is_approved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
