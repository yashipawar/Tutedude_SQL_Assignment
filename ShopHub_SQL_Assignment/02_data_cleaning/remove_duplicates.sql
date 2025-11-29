-- 02_data_cleaning/remove_duplicates.sql
-- Scripts to remove or deduplicate problematic records

-- Remove duplicate customers keeping first occurrence (by customer_id)
WITH cte AS (
  SELECT customer_id, customer_unique_id,
         ROW_NUMBER() OVER(PARTITION BY customer_unique_id ORDER BY customer_id) AS rn
  FROM customers
)
DELETE c
FROM customers c
JOIN (SELECT customer_id FROM cte WHERE rn > 1) d ON c.customer_id = d.customer_id;

-- Remove duplicate geolocation rows keeping first for each zip prefix
CREATE TABLE geolocation_dedup AS
SELECT geolocation_zip_code_prefix, 
       MIN(geolocation_id) AS geolocation_id,
       MIN(geolocation_lat) AS geolocation_lat,
       MIN(geolocation_lng) AS geolocation_lng,
       MIN(geolocation_city) AS geolocation_city,
       MIN(geolocation_state) AS geolocation_state
FROM geolocation
GROUP BY geolocation_zip_code_prefix;

-- Replace original table (optional, take backup first)
-- RENAME TABLE geolocation TO geolocation_backup;
-- RENAME TABLE geolocation_dedup TO geolocation;
