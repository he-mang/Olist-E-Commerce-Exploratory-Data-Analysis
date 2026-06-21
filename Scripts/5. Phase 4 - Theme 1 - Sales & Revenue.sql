-- 1. Monthly Revenue Trend
SELECT
	FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS order_month,
	COUNT(DISTINCT o.order_id) AS total_orders,
	SUM(oi.price + oi.freight_value) AS total_revenue,
	AVG(oi.price + oi.freight_value) AS avg_order_value
FROM vw_delivered_orders AS o
INNER JOIN order_items AS oi
	ON o.order_id = oi.order_id
GROUP BY FORMAT(o.order_purchase_timestamp, 'yyyy-MM')
ORDER BY order_month;

-- 2. Top 10 product categories by revenue
SELECT TOP 10
	p.category_english AS Category,
	COUNT(DISTINCT o.order_id) AS total_orders,
	SUM(oi.price + oi.freight_value) AS total_revenue,
	AVG(oi.price + oi.freight_value) AS avg_item_price
FROM vw_delivered_orders AS o
INNER JOIN order_items AS oi
	ON o.order_id = oi.order_id
INNER JOIN vw_products_translated AS p
	ON oi.product_id = p.product_id
GROUP BY p.category_english
ORDER BY total_revenue DESC;

-- 3. Average order value by state (top 10)
WITH order_totals AS (
	SELECT
		o.order_id,
		c.customer_state,
		SUM(oi.price + oi.freight_value) AS order_value
	FROM vw_delivered_orders AS o
	INNER JOIN order_items AS oi
		ON o.order_id = oi.order_id
	INNER JOIN customers AS c
		ON o.customer_id = c.customer_id
	GROUP BY o.order_id, c.customer_state
)
SELECT TOP 10
	customer_state,
	COUNT(order_id) AS total_orders,
	AVG(order_value) AS avg_order_value,
	SUM(order_value) AS total_revenue
FROM order_totals
GROUP BY customer_state
ORDER BY total_revenue DESC;