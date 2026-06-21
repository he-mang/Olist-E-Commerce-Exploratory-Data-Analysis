/*
========== PHASE 3 - Data Cleaning and Prep ==========
1. Handeling NULLS (e.g. missing review scores, delivery dates)
2. Parse and convert timestamp columns to DATE/DATETIME
3. Removing Duplicates and flagging outliers in price & freight columns
*/

/*
1. Handeling NULLS by creating a clean delivered orders view for use in Phase 4.
The 2,965 null delivery dates and 160 null 'approved_at' values don't need to be filled in as they're valid.
But we need a clean filtered view for delivery analysis.
*/
CREATE VIEW vw_delivered_orders AS
SELECT *
FROM orders
WHERE order_status = 'delivered'
AND order_delivered_customer_date IS NOT NULL
AND order_approved_at IS NOT NULL;

-- 2. Calculating delivery time in days
SELECT
	order_id,
	order_purchase_timestamp,
	order_delivered_customer_date,
	DATEDIFF(day, order_purchase_timestamp, order_delivered_customer_date) AS delivery_days
FROM orders
WHERE order_status = 'delivered'
AND order_delivered_customer_date IS NOT NULL;

-- 3. Flagging late deliveries
SELECT
	order_id,
	order_estimated_delivery_date,
	order_delivered_customer_date,
	DATEDIFF(day, order_estimated_delivery_date, order_delivered_customer_date) AS days_late
FROM orders
WHERE order_status = 'delivered'
AND order_delivered_customer_date IS NOT NULL;

-- 4. Checking for price outliers in order_items
-- Orders with suspicisously low or high prices
SELECT
	COUNT(*) AS zero_or_near_zero
FROM order_items
WHERE price < 1;

-- Top 10 most expensive items
SELECT TOP 10
	order_id, 
	product_id,
	price
FROM order_items
ORDER BY price DESC;

/*
5. Adding English category names to Products
Creating a clean products reference using COALESCE so we never have to repeat this join.
*/
CREATE VIEW vw_products_translated AS
SELECT
	p.product_id,
	p.product_category_name,
	COALESCE(t.product_category_name_english, p.product_category_name) AS category_english,
	p.product_weight_g,
	p.product_length_cm,
	p.product_height_cm,
	p.product_width_cm
FROM products AS p
LEFT JOIN product_category_name_translation AS t
	ON p.product_category_name = t.product_category_name;

-- 6. Checking for Duplicate orders or reviews
-- Duplicate order_id?
SELECT
	order_id,
	COUNT(*) AS cnt
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Duplicate review_id?
SELECT
	review_id,
	COUNT(*) AS cnt
FROM order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1

-- Checking what the duplicate reviews look like
SELECT
	review_id,
	order_id,
	review_score,
	review_creation_date
FROM order_reviews
WHERE review_id IN (
	SELECT review_id
	FROM order_reviews
	GROUP BY review_id
	HAVING COUNT(*) > 1
)
ORDER BY review_id;
/*
It appears that the same review was applied to multiple different orders,
a data quality issue in Olist's source system, not something that happened during import.
*/

-- How many unique review ids are affected?
SELECT
	COUNT(DISTINCT review_id) AS affected_reviews
FROM order_reviews
WHERE review_id IN (
	SELECT review_id
	FROM order_reviews
	GROUP BY review_id
	HAVING COUNT(*) > 1
);

-- How many total duplicate rows does it create?
SELECT
	COUNT(*) AS total_duplicate_rows
FROM order_reviews
WHERE review_id IN (
	SELECT review_id
	FROM order_reviews
	GROUP BY review_id
	HAVING COUNT(*) > 1
);

-- Creating a deduplicated view to take care of the duplicates
CREATE VIEW vw_reviews_deduped AS
SELECT *
FROM (
	SELECT
		*,
		ROW_NUMBER() OVER(PARTITION BY review_id ORDER BY review_creation_date DESC) AS rn
	FROM order_reviews
) AS ranked
WHERE rn = 1;

-- Verifying the row count looks right after deduplication
SELECT
	COUNT(*) AS total_rows_after_dedup
FROM vw_reviews_deduped;

-- Total rows in the original table
SELECT COUNT(*) AS total_rows FROM order_reviews;

/*
When a review_id appears twice, that's 1 extra row (you keep 1, remove 1).
When a review_id appears three times, that's 2 extra rows (you keep 1, remove 2).
764 + 25 = 789 is the number of affected review_ids. 
But the number of rows removed is 764 × 1 + 25 × 2 = 814, 
which is exactly what your query confirmed (99,224 − 98,410 = 814).
*/