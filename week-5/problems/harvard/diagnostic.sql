-- Check total database size
PRAGMA page_count;

PRAGMA page_size;

-- Determine the size of current indexes
SELECT name, SUM(pgsize) AS size
FROM dbstat
WHERE name IN ('enrollments', 'courses', 'students')
GROUP BY name;
