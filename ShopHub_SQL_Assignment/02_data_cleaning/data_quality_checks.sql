-- 02_data_cleaning/data_quality_checks.sql
-- Detection queries for data quality issues in Olist dataset

-- 1. Duplicate customer_unique_id
SELECT customer_unique_id, COUNT(*) AS cnt
FROM customers
GROUP BY customer_unique_id
HAVING COUNT(*) > 1;

-- 2. Orphan orders (orders with missing customer)
SELECT o.*
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 3. Orders without items
SELECT o.*
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL;

-- 4. Orphan order_items (missing products)
SELECT oi.*
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- 5. Null product categories
SELECT COUNT(*) AS null_category_count FROM products WHERE product_category_name IS NULL;

-- 6. Inconsistent city names (sample)
SELECT DISTINCT customer_city FROM customers ORDER BY customer_city LIMIT 200;

-- 7. Payments not matching totals
SELECT *
FROM (
    SELECT o.order_id,
           SUM(oi.price + COALESCE(oi.freight_value,0)) AS item_total,
           SUM(op.payment_value) AS payment_total
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN order_payments op ON o.order_id = op.order_id
    GROUP BY o.order_id
) t
WHERE ROUND(item_total,2) != ROUND(payment_total,2);

-- 8. Reviews missing comments
SELECT COUNT(*) AS reviews_null_comments FROM order_reviews WHERE review_comment_message IS NULL;

-- 9. Invalid timestamps
SELECT *
FROM orders
WHERE order_delivered_customer_date < order_purchase_timestamp;

-- 10. Sellers without products (no order_items)
SELECT s.*
FROM sellers s
LEFT JOIN order_items oi ON s.seller_id = oi.seller_id
WHERE oi.seller_id IS NULL;

-- 11. Geolocation duplicates by prefix
SELECT geolocation_zip_code_prefix, COUNT(*) AS cnt
FROM geolocation
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(*) > 1;

-- 12. Missing geolocation city/state
SELECT *
FROM geolocation
WHERE geolocation_city IS NULL OR geolocation_state IS NULL;
