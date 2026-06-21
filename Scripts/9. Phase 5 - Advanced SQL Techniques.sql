-- 14. Month over Month revenue growth rate
WITH monthly_revenue AS (
	SELECT
		FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS order_month,
		SUM(oi.price + oi.freight_value) AS total_revenue
	FROM vw_delivered_orders AS o
	INNER JOIN order_items AS oi
		ON o.order_id = oi.order_id
	GROUP BY FORMAT(o.order_purchase_timestamp, 'yyyy-MM')
),
revenue_with_lag AS (
	SELECT
		order_month,
		total_revenue,
		LAG(total_revenue) OVER (ORDER BY order_month) AS prev_month_revenue
	FROM monthly_revenue
)
SELECT
	order_month,
	total_revenue,
	prev_month_revenue,
	CAST((total_revenue - prev_month_revenue) * 100.0 / prev_month_revenue AS DECIMAL(18,2)) AS mom_growth_pct
FROM revenue_with_lag
WHERE prev_month_revenue IS NOT NULL
	AND order_month >= '2017-01'
ORDER BY order_month;

-- 15. Cumulative revenue over time
WITH monthly_revenue AS (
	SELECT
		FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS order_month,
		SUM(oi.price + oi.freight_value) AS total_revenue
	FROM vw_delivered_orders AS o
	INNER JOIN order_items AS oi
		ON o.order_id = oi.order_id
	GROUP BY FORMAT(o.order_purchase_timestamp, 'yyyy-MM')
)
SELECT
	order_month,
	total_revenue,
	SUM(total_revenue) OVER(ORDER BY order_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue
FROM monthly_revenue
WHERE order_month >= '2017-01'
ORDER BY order_month;

--16. Customer Cohort Retention Analysis
WITH first_orders AS (
	-- Step 1: Finding each customer's first order month
	SELECT
		c.customer_unique_id,
		MIN(FORMAT(o.order_purchase_timestamp, 'yyyy-MM')) AS cohort_month
	FROM vw_delivered_orders AS o
	INNER JOIN customers AS c
		ON o.customer_id = c.customer_id
	GROUP BY c.customer_unique_id
),
customer_orders AS (
	-- Step 2: Calculating how many months after cohort each order was placed
	SELECT
		f.customer_unique_id,
		f.cohort_month,
		FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS order_month,
		DATEDIFF(
			month,
			CAST(f.cohort_month + '-01' AS DATE),
			CAST(FORMAT(o.order_purchase_timestamp, 'yyyy-MM') + '-01' AS DATE)
		) AS months_since_first_order
	FROM first_orders AS f
	INNER JOIN customers AS c
		ON f.customer_unique_id = c.customer_unique_id
	INNER JOIN vw_delivered_orders AS o
		ON c.customer_id = o.customer_id
),
cohort_sizes AS (
	-- Step 3a: Counting how many customers are in each cohort
	SELECT
		cohort_month,
		COUNT(DISTINCT customer_unique_id) AS cohort_size
	FROM first_orders
	GROUP BY cohort_month
),
cohort_retention AS (
	-- Step 3b: Counting how many customers from each cohort ordered in each subsequent month
	SELECT
		cohort_month,
		months_since_first_order,
		COUNT(DISTINCT customer_unique_id) AS active_customers
	FROM customer_orders
	GROUP BY cohort_month, months_since_first_order
)
SELECT
	r.cohort_month,
	s.cohort_size,
	r.months_since_first_order,
	r.active_customers,
	CAST(r.active_customers * 100.0 / s.cohort_size AS DECIMAL(5,2)) AS retention_pct
FROM cohort_retention AS r
INNER JOIN cohort_sizes AS s
	ON r.cohort_month = s.cohort_month
WHERE r.cohort_month >= '2017-01'
	AND r.months_since_first_order <= 12
ORDER BY r.cohort_month, r.months_since_first_order;