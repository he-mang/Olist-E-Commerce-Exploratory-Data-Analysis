-- ========== Phase 2: Schema Exploration ==========
-- Understand all 9 tables and their relationships (ERD)
-- Check row counts, nulls, and distinct values per column
-- Identify primary & foreign keys, validate joins between tables
-- =================================================

-- ========== 1. Understanding the relationships, Validting key joins ==========
-- Do all orders have a matching customer?
SELECT
	COUNT(*) AS orders_without_customer
FROM orders AS o
LEFT JOIN customers AS c
ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Do all order_items have a matching order?
SELECT
	COUNT(*) AS items_without_order
FROM order_items AS oi
LEFT JOIN orders AS o
ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Do all order_items have a matching product?
SELECT
	COUNT(*) AS items_without_product
FROM order_items AS oi
LEFT JOIN products AS p
ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Do all order_items have a matching seller?
SELECT
	COUNT(*) AS items_without_seller
FROM order_items AS oi
LEFT JOIN sellers AS s
ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

-- ========== 2. Checking for Nulls in critical columns ==========
SELECT
	SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS null_delivery_date,
	SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) AS null_approved_at,
	SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END) AS null_estimated_delivery
FROM orders;

SELECT
	SUM(CASE WHEN review_score IS NULL THEN 1 ELSE 0 END) AS null_review_score,
	SUM(CASE WHEN review_comment_message IS NULL THEN 1 ELSE 0 END) AS null_comment
FROM order_reviews;

-- ========== 3. Understanding the range and shape of the data ==========
-- Date range of the dataset
SELECT
	MIN(order_purchase_timestamp) AS earliest_order,
	MAX(order_purchase_timestamp) AS latest_order
FROM orders;

-- Order status breakdown
SELECT
	order_status,
	COUNT(*) AS total
FROM orders
GROUP BY order_status
ORDER BY total DESC;

-- Review score distribution
SELECT
	review_score,
	COUNT(*) AS total
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;

-- Price range in order_items
SELECT
	MIN(price) AS min_price,
	MAX(price) AS max_price,
	AVG(price) AS avg_price
FROM order_items;

-- ========== 4. Checking the product category translation join ==========
-- How many products have an English category name?
SELECT
	COUNT(*) AS products_with_english_category
FROM products AS p
INNER JOIN product_category_name_translation AS t -- I did an inner join because i only want the matching results from the Products table.
ON p.product_category_name = t.product_category_name;

-- How many products dont have an English category name?
SELECT 
	COUNT(*) AS products_with_english_category
FROM products p
LEFT JOIN product_category_name_translation t
ON p.product_category_name = t.product_category_name
WHERE t.product_category_name IS NULL;