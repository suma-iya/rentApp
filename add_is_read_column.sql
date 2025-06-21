-- Add is_read column to notification table
ALTER TABLE notification ADD COLUMN is_read BOOLEAN DEFAULT FALSE;

-- Update existing notifications to be marked as read
UPDATE notification SET is_read = TRUE; 