-- 11. Top 10 sellers by revenue
SELECT TOP 10
	oi.seller_id,
	COUNT(DISTINCT oi.order_id) AS total_orders,
	SUM(oi.price + oi.freight_value) AS total_revenue,
	AVG(oi.price + oi.freight_value) AS avg_order_value
FROM order_items AS oi
INNER JOIN vw_delivered_orders AS o
	ON oi.order_id = o.order_id
GROUP BY oi.seller_id
ORDER BY total_revenue DESC;

/*
12. Top 10 sellers with the highest late delivery rate (minimum 50 orders)
The filter for minimum 50 orders is important, without it, a seller with 1 order that arrived
late would show 100% late rate, which is statistically meaningless.
50 orders gives a reliable enough sample size.
*/
WITH seller_delivery AS (
	SELECT
		oi.seller_id,
		COUNT(DISTINCT o.order_id) AS total_orders,
		SUM(CASE
				WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
				THEN 1
				ELSE 0
			END) AS late_orders
	FROM vw_delivered_orders AS o
	INNER JOIN order_items AS oi
		ON o.order_id = oi.order_id
	GROUP BY oi.seller_id
)
SELECT TOP 10
	seller_id,
	total_orders,
	late_orders,
	CAST(late_orders * 100 / total_orders AS DECIMAL(5,2)) AS late_delivery_pct
FROM seller_delivery
WHERE total_orders >= 50
ORDER BY late_delivery_pct DESC;

/*
13. Average review score by freight cost bucket
This query asks do customers who pay more for shipping rate their experience lower?
High freight costs are a known driver of customer dissatisfaction in e-commerce.
*/
WITH freight_buckets AS (
	SELECT
		r.review_id,
		r.review_score,
		oi.freight_value,
		CASE
			WHEN oi.freight_value < 10 THEN 'Under R$10'
			WHEN oi.freight_value BETWEEN 10 AND 24.99 THEN 'R$10 - R$24.99'
			WHEN oi.freight_value BETWEEN 25 AND 49.99 THEN 'R$25 - R$49.99'
			WHEN oi.freight_value BETWEEN 50 AND 99.99 THEN 'R$50 - R$99.99'
			ELSE 'R$100+'
		END AS freight_bucket
	FROM vw_reviews_deduped AS r
	INNER JOIN vw_delivered_orders AS o
		ON r.order_id = o.order_id
	INNER JOIN order_items AS oi
		ON o.order_id = oi.order_id
)
SELECT
	freight_bucket,
	COUNT(review_id) AS total_review,
	AVG(CAST(review_score AS FLOAT)) AS avg_review_score
FROM freight_buckets
GROUP BY freight_bucket
ORDER BY avg_review_score DESC;