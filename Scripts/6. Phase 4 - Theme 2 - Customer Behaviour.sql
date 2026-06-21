-- 4. Repeat vs One-time buyers
WITH customer_order_counts AS (
	SELECT
		c.customer_unique_id,
		COUNT(o.order_id) AS total_orders
	FROM vw_delivered_orders AS o
	INNER JOIN customers AS c
		ON o.customer_id = c.customer_id
	GROUP BY c.customer_unique_id
)
SELECT
	CASE
		WHEN total_orders = 1 THEN 'One-time buyer'
		WHEN total_orders = 2 THEN 'Twice'
		WHEN total_orders >= 3 THEN 'Three or more times'
	END AS customer_segment,
	COUNT(customer_unique_id) AS total_customers,
	CAST(COUNT(customer_unique_id) * 100 / 
		SUM(COUNT(customer_unique_id)) OVER() AS DECIMAL(5,2)) AS pct_of_customers
FROM customer_order_counts
GROUP BY 
	CASE
		WHEN total_orders = 1 THEN 'One-time buyer'
		WHEN total_orders = 2 THEN 'Twice'
		WHEN total_orders >= 3 THEN 'Three or more times'
	END
ORDER BY total_customers DESC;

-- 5. Top 10 states by customer count
SELECT TOP 10
	c.customer_state,
	COUNT(DISTINCT c.customer_unique_id) AS total_customers,
	CAST(COUNT(DISTINCT c.customer_unique_id) * 100 / 
		SUM(COUNT(DISTINCT c.customer_unique_id)) OVER() AS DECIMAL(5,2)) AS pct_of_customers
FROM customers AS c
GROUP BY c.customer_state
ORDER BY total_customers DESC;

-- 6. How many orders do customers typically place (order frequency distribution)
WITH customer_order_counts AS (
	SELECT
		c.customer_unique_id,
		COUNT(o.order_ID) AS total_orders
	FROM vw_delivered_orders AS o
	INNER JOIN customers AS c
		ON o.customer_id = c.customer_id
	GROUP BY c.customer_unique_id
)
SELECT
	total_orders AS orders_places,
	COUNT(*) AS total_customers
FROM customer_order_counts
GROUP BY total_orders
ORDER BY total_orders;