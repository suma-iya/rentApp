-- Add status column to floor table
ALTER TABLE floor ADD COLUMN status VARCHAR(20) DEFAULT NULL;

-- Update existing floors to have appropriate status
UPDATE floor SET status = 'occupied' WHERE tenant IS NOT NULL;
UPDATE floor SET status = 'available' WHERE tenant IS NULL; 