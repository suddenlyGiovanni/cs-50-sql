CREATE VIEW frequently_reviewed AS
SELECT l.id, l.property_type, l.host_name, COUNT(r.listing_id) AS reviews
FROM reviews              r
       JOIN main.listings l ON l.id = r.listing_id
GROUP BY listing_id
ORDER BY reviews DESC, l.property_type ASC, l.host_name ASC
LIMIT 100;
