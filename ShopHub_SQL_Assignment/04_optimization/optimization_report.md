# Optimization Report

## Overview
This report documents the queries analyzed for performance, the indexes applied, and the expected impact.

## Queries analyzed
1. Orders join with order_items and order_payments (aggregation)
2. Product revenue aggregation (products JOIN order_items)
3. Customer order counts (orders GROUP BY customer_id)

## Baseline (before)
- EXPLAIN ANALYZE outputs should be pasted in 04_optimization/explain_before.txt
- Observed issues: full table scans on large tables (order_items, order_payments), which led to high execution times.

## Optimization actions
- Created indexes:
  - idx_order_items_order_id ON order_items(order_id)
  - idx_order_payments_order_id ON order_payments(order_id)
  - idx_order_items_product_id ON order_items(product_id)
  - idx_orders_customer_id ON orders(customer_id)

## Rationale
- Queries that join on order_id benefit from having order_id indexed on child tables.
- Aggregations grouping by customer_id run faster when orders.customer_id is indexed.

## After
- Re-run EXPLAIN ANALYZE and paste outputs in 04_optimization/explain_after.txt
- Compare execution time and query plans. Expect reduction in scanned rows and lower execution time.

## Recommendations
- Consider composite indexes if queries filter on multiple columns.
- Monitor slow_queries log and add indexes selectively.
