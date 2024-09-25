-- *** The Lost Letter ***
-- 1. from the addresses table we can derive the address_id of ms Anneke
-- 2. with Ms Anneke's address id, we can get a hold of her packages;
--    from the packages table we can get all of Anneke's packages matching her
--    `from_address_id`.
--    we also need to discriminate the one matching her content description.
--    Now we have the package_id
-- 3. with said package_id we can to the scans and check if it has been correctly droped and where.
-- 4. last piece missing is to correlate back the package to its destination address
WITH FromAddress AS (SELECT a.id
                     FROM addresses a
                     WHERE a.address = '900 Somerville Avenue'),
     TargetPackage AS (SELECT p.to_address_id
                       FROM packages p
                              JOIN scans ON p.id = scans.package_id
                       WHERE from_address_id = (SELECT FromAddress.id
                                                FROM FromAddress)
                         AND p.contents LIKE '%congratulatory%'
                         AND scans.action = 'Drop')
SELECT a.type, a.address
FROM addresses a
WHERE id = (SELECT TargetPackage.to_address_id
            FROM TargetPackage);

-- *** The Devious Delivery ***
WITH PackageID AS (SELECT p.id,
                          p.contents
                   FROM packages p
                   WHERE from_address_id ISNULL),
     ScanDrop AS (SELECT s.package_id,
                         s.address_id,
                         s.action,
                         s.timestamp,
                         p.contents
                  FROM scans s
                         JOIN packages p ON s.package_id = p.id
                  WHERE EXISTS(SELECT 1
                               FROM PackageID p
                               WHERE p.id = s.package_id)
                    AND action = 'Drop')
SELECT a.address,
       a.type,
       s.contents,
       s.action,
       s.package_id,
       s.timestamp
FROM addresses a
       JOIN ScanDrop AS s ON a.id = s.address_id;


-- *** The Forgotten Gift ***
-- mystery gift
-- from: 109 Tileston Street.
-- to: 728 Maple Place
WITH SernderAddress AS (SELECT a.id
                        FROM addresses a
                        WHERE address = '109 Tileston Street'),
     ReciverAddress AS (SELECT a.id
                        FROM addresses a
                        WHERE address = '728 Maple Place')

SELECT *
FROM packages p
       JOIN scans s ON p.id = s.package_id
       JOIN drivers d ON s.driver_id = d.id
WHERE p.from_address_id = (SELECT id FROM SernderAddress)
  AND p.to_address_id = (SELECT id FROM ReciverAddress)
ORDER BY s.timestamp DESC
LIMIT 1;
