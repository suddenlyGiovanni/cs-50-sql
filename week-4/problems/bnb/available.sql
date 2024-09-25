CREATE VIEW available AS
SELECT l.id, l.property_type, l.host_name, a.date
FROM availabilities       a
       JOIN main.listings l ON l.id = a.listing_id
WHERE a.available = 'TRUE';
