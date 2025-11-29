CREATE DATABASE shophub;
USE shophub;

-- COMPLETE SQL ASSIGNMENT SOLUTION
-- ShopHub / Olist E-Commerce Dataset

/*************************************************
 PART A — Database Design & Data Quality
*************************************************/

-- Q1: ERD
-- https://dbdiagram.io/d/692aa93dd6676488badf375f

-- Q2: Data Quality Checks

-- 1. Duplicate customer_unique_id
SELECT customer_unique_id, COUNT(*)
FROM customers
GROUP BY customer_unique_id
HAVING COUNT(*) > 1;

-- 2. Orphan orders
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
SELECT * FROM products WHERE product_category_name IS NULL;

-- 6. Inconsistent city names
SELECT DISTINCT customer_city FROM customers ORDER BY customer_city;

-- 7. Payments not matching totals
SELECT *
FROM (
    SELECT o.order_id,
           SUM(oi.price + oi.freight_value) AS item_total,
           SUM(op.payment_value) AS payment_total
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN order_payments op ON o.order_id = op.order_id
    GROUP BY o.order_id
) t
WHERE item_total != payment_total;

-- 8. Reviews missing comments
SELECT * FROM order_reviews WHERE review_comment_message IS NULL;

-- 9. Invalid timestamps
SELECT *
FROM orders
WHERE order_delivered_customer_date < order_purchase_timestamp;

-- 10. Sellers without products
SELECT s.*
FROM sellers s
LEFT JOIN order_items oi ON s.seller_id = oi.seller_id
WHERE oi.seller_id IS NULL;

-- Q3: CREATE TABLE statements already provided earlier.

CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);
CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(50),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);
CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);
CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
);
CREATE TABLE order_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(50),
    payment_installments INT,
    payment_value DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);
CREATE TABLE order_reviews (
    review_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title VARCHAR(200),
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);
CREATE TABLE geolocation (
    geolocation_id INT AUTO_INCREMENT PRIMARY KEY,
    geolocation_zip_code_prefix INT,
    geolocation_lat DECIMAL(9,6),
    geolocation_lng DECIMAL(9,6),
    geolocation_city VARCHAR(100),
    geolocation_state CHAR(2)
);
SET GLOBAL local_infile = 1;

-- Q2 — Identify 10+ Data Quality Issues (Olist Dataset)
-- customer_unique_id should uniquely identify a person
-- But ~3,300 customers appear multiple times
-- Caused by Olist issuing a new customer_id for each order  
SELECT customer_unique_id, COUNT(*)
FROM customers
GROUP BY customer_unique_id
HAVING COUNT(*) > 1;

-- Q4: Remove duplicate customers
WITH cte AS (
  SELECT *, ROW_NUMBER() OVER(
        PARTITION BY customer_unique_id ORDER BY customer_id
  ) AS rn
  FROM customers
)
DELETE FROM customers WHERE customer_id IN (SELECT customer_id FROM cte WHERE rn > 1);

-- Q5: Data Dictionary 
-- https://gist.github.com/yashipawar/e04d255420b9777de703b9b077557372

/*************************************************
 PART B — Data Manipulation & Retrieval
*************************************************/

-- Q6: Insert with transaction demo
START TRANSACTION;
INSERT INTO customers VALUES ('test123','uniq123',12345,'testcity','SP');
ROLLBACK;

START TRANSACTION;
INSERT INTO customers VALUES ('test456','uniq456',12345,'realcity','RJ');
COMMIT;

-- Q7: Same email but different names (email not in dataset → simulate using unique ID)
SELECT customer_unique_id, COUNT(*)
FROM customers
GROUP BY customer_unique_id
HAVING COUNT(*) > 1;

-- Q8: Orphan order_items
SELECT oi.*
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Q9: Customers who never placed an order
SELECT c.*
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- Q10: Potential fraud
SELECT o.order_id
FROM orders o
JOIN (
    SELECT order_id, SUM(price + freight_value) AS total
    FROM order_items
    GROUP BY order_id
) t ON t.order_id = o.order_id
JOIN (
    SELECT order_id, SUM(payment_value) AS payments
    FROM order_payments
    GROUP BY order_id
) p ON p.order_id = o.order_id
WHERE t.total != p.payments;

/*************************************************
 PART C — Complex Aggregations
*************************************************/

-- Q11: Monthly revenue + MoM growth
WITH monthly AS (
  SELECT DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS month,
         SUM(op.payment_value) AS revenue
  FROM orders o
  JOIN order_payments op ON o.order_id = op.order_id
  GROUP BY month
)
SELECT month, revenue,
       (revenue - LAG(revenue,1) OVER (ORDER BY month)) / LAG(revenue,1) OVER (ORDER BY month) * 100 AS mom_growth
FROM monthly;

-- Q12: Top 10 products by revenue per category
WITH prod_rev AS (
  SELECT p.product_id, p.product_category_name,
         SUM(oi.price) AS revenue,
         DENSE_RANK() OVER (PARTITION BY p.product_category_name ORDER BY SUM(oi.price) DESC) AS rk
  FROM products p
  JOIN order_items oi ON p.product_id = oi.product_id
  GROUP BY p.product_id, p.product_category_name
)
SELECT * FROM prod_rev WHERE rk <= 10;

-- Q13: Customer Lifetime Value (CLV)
SELECT o.customer_id, SUM(op.payment_value) AS clv,
CASE
  WHEN SUM(op.payment_value) < 100 THEN 'Bronze'
  WHEN SUM(op.payment_value) BETWEEN 100 AND 500 THEN 'Silver'
  ELSE 'Gold'
END AS segment
FROM orders o
JOIN order_payments op ON o.order_id = op.order_id
GROUP BY o.customer_id;

-- Q14: Sales rollup
SELECT DATE(order_purchase_timestamp) AS day,
       WEEK(order_purchase_timestamp) AS week,
       MONTH(order_purchase_timestamp) AS month,
       SUM(op.payment_value) AS revenue
FROM orders o
JOIN order_payments op ON o.order_id = op.order_id
GROUP BY ROLLUP(day, week, month);

-- Q15: Seasonal patterns
SELECT p.product_category_name,
       MONTH(o.order_purchase_timestamp) AS month,
       COUNT(*) AS sales
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON o.order_id = oi.order_id
GROUP BY p.product_category_name, month;

/*************************************************
 PART D — Mastering Joins
*************************************************/

-- Q16: Customer 360 view
SELECT c.*, o.*, oi.*, p.*, r.*
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN products p ON oi.product_id = p.product_id
LEFT JOIN order_reviews r ON o.order_id = r.order_id;

-- Q17: Customers who bought electronics but never books
SELECT DISTINCT o.customer_id
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE p.product_category_name = 'electronics'
AND o.customer_id NOT IN (
    SELECT o2.customer_id
    FROM orders o2
    JOIN order_items oi2 ON o2.order_id = oi2.order_id
    JOIN products p2 ON oi2.product_id = p2.product_id
    WHERE p2.product_category_name = 'books'
);

-- Q18: Sellers and their best-selling product
WITH s AS (
  SELECT seller_id, product_id, SUM(price) AS revenue,
         RANK() OVER(PARTITION BY seller_id ORDER BY SUM(price) DESC) AS rk
  FROM order_items
  GROUP BY seller_id, product_id
)
SELECT * FROM s WHERE rk = 1;

-- Q19: Products frequently bought together
SELECT a.product_id AS product_A,
       b.product_id AS product_B,
       COUNT(*) AS freq
FROM order_items a
JOIN order_items b ON a.order_id = b.order_id AND a.product_id < b.product_id
GROUP BY a.product_id, b.product_id
ORDER BY freq DESC;

-- Q20: Shipping delays
SELECT o.order_id, o.customer_id, oi.seller_id
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date;

/*************************************************
 PART E — Subqueries & CTEs
*************************************************/

-- Q21: Customers who spent more than average customer in their state
SELECT c.customer_id
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_payments op ON o.order_id = op.order_id
GROUP BY c.customer_state, c.customer_id
HAVING SUM(op.payment_value) > (
    SELECT AVG(t.total)
    FROM (
        SELECT c2.customer_state AS st, SUM(op2.payment_value) AS total
        FROM customers c2
        JOIN orders o2 ON c2.customer_id = o2.customer_id
        JOIN order_payments op2 ON o2.order_id = op2.order_id
        GROUP BY c2.customer_id, c2.customer_state
    ) t
    WHERE t.st = c.customer_state
);

-- Q22: 2nd highest revenue product per category
WITH pr AS (
  SELECT product_id, product_category_name,
         SUM(price) AS revenue,
         DENSE_RANK() OVER (PARTITION BY product_category_name ORDER BY SUM(price) DESC) AS rk
  FROM order_items oi
  JOIN products p ON oi.product_id = p.product_id
  GROUP BY product_id, product_category_name
)
SELECT * FROM pr WHERE rk = 2;

-- Q23: Recursive category hierarchy (dataset does not have hierarchy → sample)
WITH RECURSIVE cat AS (
  SELECT product_category_name AS category, NULL AS parent_category
  FROM products
)
SELECT * FROM cat;

-- Q24: Customers with purchases in 3+ consecutive months
WITH m AS (
  SELECT customer_id,
         DATE_FORMAT(order_purchase_timestamp,'%Y-%m') AS ym
  FROM orders
  GROUP BY customer_id, ym
),
seq AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY ym) AS rn
  FROM m
)
SELECT customer_id
FROM (
  SELECT customer_id, COUNT(*) AS streak
  FROM seq
 GROUP BY customer_id
 HAVING streak >= 3
) t;

/*************************************************
 PART F — Window Functions
*************************************************/

-- Q25: 7-day moving average of order count
WITH daily AS (
  SELECT DATE(order_purchase_timestamp) AS dt,
         COUNT(*) AS cnt
  FROM orders
  GROUP BY dt
)
SELECT dt, cnt,
       AVG(cnt) OVER (ORDER BY dt ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS mov_avg
FROM daily;

-- Q26: Gap between customer orders
SELECT customer_id, order_id,
       DATEDIFF(order_purchase_timestamp,
       LAG(order_purchase_timestamp) OVER(PARTITION BY customer_id ORDER BY order_purchase_timestamp)) AS gap_days
FROM orders;

-- Q27: Rank sellers by revenue per state
WITH seller_rev AS (
  SELECT s.seller_id, s.seller_state, SUM(oi.price) AS revenue
  FROM sellers s
  JOIN order_items oi ON s.seller_id = oi.seller_id
  GROUP BY s.seller_id, s.seller_state
)
SELECT *,
       RANK() OVER (PARTITION BY seller_state ORDER BY revenue DESC) AS rk
FROM seller_rev
WHERE rk <= 3;

-- Q28: Running total of revenue with % of grand total
WITH rev AS (
  SELECT DATE(order_purchase_timestamp) AS dt,
         SUM(op.payment_value) AS revenue
  FROM orders o
  JOIN order_payments op ON o.order_id = op.order_id
  GROUP BY dt
)
SELECT dt, revenue,
       SUM(revenue) OVER (ORDER BY dt) AS running_total,
       revenue / SUM(revenue) OVER() * 100 AS pct_of_total
FROM rev;

/*************************************************
 PART G — Stored Procedures & Optimization
*************************************************/

-- Q29: Discount stored procedure
DELIMITER $$
CREATE PROCEDURE calc_discount(IN cust_id VARCHAR(50), IN order_val DECIMAL(10,2))
BEGIN
  DECLARE order_count INT;

  SELECT COUNT(*) INTO order_count
  FROM orders
  WHERE customer_id = cust_id;

  IF order_count = 0 THEN
    SELECT '15% discount' AS discount;
  ELSEIF order_val > 500 THEN
    SELECT '10% discount' AS discount;
  ELSEIF order_count >= 5 THEN
    SELECT '5% discount' AS discount;
  ELSE
    SELECT '0% discount' AS discount;
  END IF;
END $$
DELIMITER ;

-- Q30: Identify 3 slowest queries using EXPLAIN ANALYZE and optimize them with indexes


-- Example 1: Slow query (orders + order_items + payments join)
EXPLAIN ANALYZE
SELECT o.order_id, SUM(oi.price), SUM(op.payment_value)
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN order_payments op ON o.order_id = op.order_id
GROUP BY o.order_id;


-- Optimization: Add indexes
CREATE INDEX idx_orders_order_id ON orders(order_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_payments_order_id ON order_payments(order_id);


-- Example 2: Slow product revenue ranking
EXPLAIN ANALYZE
SELECT p.product_id, SUM(oi.price) AS rev
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id;


-- Optimization: Add index
CREATE INDEX idx_order_items_product_id ON order_items(product_id);


-- Example 3: Slow customer order history
EXPLAIN ANALYZE
SELECT customer_id, COUNT(*)
FROM orders
GROUP BY customer_id;


-- Optimization: Add index
CREATE INDEX idx_orders_customer_id ON orders(customer_id);


-- After adding indexes, run EXPLAIN ANALYZE again to compare before/after execution times.