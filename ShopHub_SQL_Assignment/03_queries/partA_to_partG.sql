-- 03_queries/partA_to_partG.sql
-- All query answers for Q6 to Q30

/*************************************************
 PART B — Data Manipulation & Retrieval
*************************************************/

-- Q6: Insert with transaction demo
START TRANSACTION;
INSERT INTO customers (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
VALUES ('test123','uniq123',12345,'testcity','SP');
ROLLBACK;

START TRANSACTION;
INSERT INTO customers (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
VALUES ('test456','uniq456',12345,'realcity','RJ');
COMMIT;

-- Q7: Same unique_id multiple times (proxy for email)
SELECT customer_unique_id, COUNT(*) AS cnt
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

-- Q10: Potential fraud (payment mismatch)
SELECT o.order_id
FROM orders o
JOIN (
    SELECT order_id, SUM(price + COALESCE(freight_value,0)) AS total
    FROM order_items
    GROUP BY order_id
) t ON t.order_id = o.order_id
JOIN (
    SELECT order_id, SUM(payment_value) AS payments
    FROM order_payments
    GROUP BY order_id
) p ON p.order_id = o.order_id
WHERE ROUND(t.total,2) != ROUND(p.payments,2);

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
       CASE
         WHEN LAG(revenue) OVER (ORDER BY month) IS NULL THEN NULL
         ELSE (revenue - LAG(revenue) OVER (ORDER BY month)) / LAG(revenue) OVER (ORDER BY month) * 100
       END AS mom_growth
FROM monthly
ORDER BY month;

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

-- Q14: Sales rollup (daily, weekly, monthly)
SELECT DATE(order_purchase_timestamp) AS day,
       WEEK(order_purchase_timestamp,1) AS week,
       MONTH(order_purchase_timestamp) AS month,
       SUM(op.payment_value) AS revenue
FROM orders o
JOIN order_payments op ON o.order_id = op.order_id
GROUP BY ROLLUP(day, week, month)
ORDER BY day;

-- Q15: Seasonal patterns
SELECT p.product_category_name,
       MONTH(o.order_purchase_timestamp) AS month,
       COUNT(*) AS sales
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON o.order_id = oi.order_id
GROUP BY p.product_category_name, month
ORDER BY p.product_category_name, month;

/*************************************************
 PART D — Mastering Joins
*************************************************/

-- Q16: Customer 360 view (sample columns)
SELECT c.customer_unique_id, c.customer_city, c.customer_state,
       o.order_id, o.order_status, o.order_purchase_timestamp,
       oi.order_item_id, oi.price, oi.freight_value,
       p.product_id, p.product_category_name,
       r.review_score, r.review_comment_message
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
SELECT seller_id, product_id, revenue
FROM s
WHERE rk = 1;

-- Q19: Products frequently bought together
SELECT a.product_id AS product_A,
       b.product_id AS product_B,
       COUNT(*) AS freq
FROM order_items a
JOIN order_items b ON a.order_id = b.order_id AND a.product_id < b.product_id
GROUP BY a.product_id, b.product_id
ORDER BY freq DESC
LIMIT 100;

-- Q20: Shipping delays
SELECT o.order_id, o.customer_id, oi.seller_id,
       o.order_estimated_delivery_date, o.order_delivered_customer_date
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
  SELECT p.product_id, p.product_category_name,
         SUM(oi.price) AS revenue,
         DENSE_RANK() OVER (PARTITION BY p.product_category_name ORDER BY SUM(oi.price) DESC) AS rk
  FROM order_items oi
  JOIN products p ON oi.product_id = p.product_id
  GROUP BY p.product_id, p.product_category_name
)
SELECT * FROM pr WHERE rk = 2;

-- Q23: Recursive category hierarchy (example)
WITH RECURSIVE cat AS (
  SELECT DISTINCT product_category_name AS category, NULL AS parent_category
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
ordered AS (
  SELECT customer_id, ym,
         ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY ym) AS rn
  FROM m
),
seq AS (
  SELECT customer_id, COUNT(*) AS streak
  FROM (
    SELECT customer_id, ym, rn, DATE_FORMAT(STR_TO_DATE(ym, '%Y-%m'), '%Y-%m') AS ym_date
    FROM ordered
  ) t
  GROUP BY customer_id
  HAVING COUNT(*) >= 3
)
SELECT customer_id FROM seq;

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
FROM daily
ORDER BY dt;

-- Q26: Gap between customer orders
SELECT customer_id, order_id,
       DATEDIFF(order_purchase_timestamp,
       LAG(order_purchase_timestamp) OVER(PARTITION BY customer_id ORDER BY order_purchase_timestamp)) AS gap_days
FROM orders;

-- Q27: Rank sellers by revenue per state (top 3)
WITH seller_rev AS (
  SELECT s.seller_id, s.seller_state, SUM(oi.price) AS revenue
  FROM sellers s
  JOIN order_items oi ON s.seller_id = oi.seller_id
  GROUP BY s.seller_id, s.seller_state
)
SELECT seller_id, seller_state, revenue
FROM (
  SELECT *, RANK() OVER (PARTITION BY seller_state ORDER BY revenue DESC) AS rk
  FROM seller_rev
) t
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
FROM rev
ORDER BY dt;

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
