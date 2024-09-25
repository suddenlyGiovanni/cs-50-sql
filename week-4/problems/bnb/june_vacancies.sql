CREATE VIEW june_vacancies AS
SELECT l.id, l.property_type, l.host_name, COUNT(a.listing_id) AS days_vacant
FROM availabilities       a
       JOIN main.listings l ON a.listing_id = l.id
WHERE a.date LIKE '2023-06%' AND a.available = 'TRUE'
GROUP BY a.listing_id;
