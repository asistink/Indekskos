ALTER TABLE listings ADD COLUMN video_url TEXT;
ALTER TABLE listings ADD COLUMN is_video_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE listings ADD COLUMN last_confirmed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE listings ADD COLUMN confirmation_token VARCHAR(255);
ALTER TABLE listings ADD COLUMN target_campus VARCHAR(255);
ALTER TABLE listings ADD COLUMN motor_distance_minutes INTEGER;
