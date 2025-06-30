-- Update existing payment notifications to use "Tk" instead of old currency symbols
UPDATE notification 
SET message = REPLACE(message, 'Payment amount: $', 'Payment amount: Tk ')
WHERE message LIKE 'Payment amount: $%';

UPDATE notification 
SET message = REPLACE(message, 'Payment amount: ৳', 'Payment amount: Tk ')
WHERE message LIKE 'Payment amount: ৳%';

UPDATE notification 
SET message = REPLACE(message, 'Payment amount: à§³', 'Payment amount: Tk ')
WHERE message LIKE 'Payment amount: à§³%';

-- Also update any notifications with the broken taka symbol encoding
UPDATE notification 
SET message = REPLACE(message, 'à§³', 'Tk ')
WHERE message LIKE '%à§³%'; 