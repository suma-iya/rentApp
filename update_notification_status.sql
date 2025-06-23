-- Update notification status column to allow NULL as default and add 'canceled' status
-- First, update existing 'pending' statuses to NULL (optional - you can keep them as 'pending' if you prefer)
-- UPDATE notification SET status = NULL WHERE status = 'pending';

-- Add 'canceled' as a valid status value (if using ENUM, you would need to modify the ENUM type)
-- For VARCHAR columns, this is not needed as any string can be inserted

-- Update the default value for new notifications to be NULL instead of 'pending'
-- Note: This change will only affect new notifications, existing ones remain unchanged
-- The application code should be updated to handle NULL status appropriately 