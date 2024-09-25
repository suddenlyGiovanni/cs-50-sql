CREATE VIEW one_bedrooms AS
SELECT l.id, l.property_type, l.host_name, l.accommodates
FROM listings l
WHERE l.bedrooms = 1;
