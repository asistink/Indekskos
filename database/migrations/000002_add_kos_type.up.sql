-- Migration: Add kos_type column to listings table
-- Values: 'putra', 'putri', 'campur'
ALTER TABLE listings ADD COLUMN IF NOT EXISTS kos_type VARCHAR(20) DEFAULT 'campur';

-- Update existing listings with random kos_type for testing
UPDATE listings SET kos_type = CASE 
    WHEN id % 3 = 0 THEN 'putra'
    WHEN id % 3 = 1 THEN 'putri'
    ELSE 'campur'
END;
