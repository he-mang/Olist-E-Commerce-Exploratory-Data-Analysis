-- 7. Average delivery time in days overall
WITH delivery_times AS (
    SELECT
        DATEDIFF(day, order_purchase_timestamp, order_delivered_customer_date) AS delivery_days
    FROM vw_delivered_orders
)
SELECT DISTINCT
    AVG(delivery_days) OVER() AS avg_delivery_days,
    MIN(delivery_days) OVER() AS min_delivery_days,
    MAX(delivery_days) OVER() AS max_delivery_days,
    PERCENTILE_CONT(0.5) WITHIN GROUP (
        ORDER BY delivery_days
    ) OVER() AS median_delivery_days
FROM delivery_times;
/*
The CTE calculates delivery duration for each order. Window functions then compute overall average, minimum, maximum,
and median delivery times across the entire dataset while preserving row granularity. By using OVER() on all four functions
including AVG, MIN, and  MAX, everything becomes a window function, so SQL Server no longer complains about mixing 
aggregates with window functions.
Since the calculated statistics are identical on every row, DISTINCT is used to return a single summary row.
*/

-- 8. Average delivery time by State (bottom 10 slowest)
SELECT TOP 10
    c.customer_state,
    COUNT(o.order_id) AS total_orders,
    AVG(DATEDIFF(day, o.order_purchase_timestamp, o.order_delivered_customer_date)) AS avg_delivery_days,
    AVG(DATEDIFF(day, o.order_delivered_customer_date, o.order_estimated_delivery_date)) AS avg_days_before_estimate
FROM vw_delivered_orders AS o
INNER JOIN customers AS c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;

-- 9. Late delivery rate overall and by state (top 10 worst)
WITH delivery_flags AS (
    SELECT
        o.order_id,
        c.customer_state,
        CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                THEN 1
            ELSE 0
        END AS is_late
    FROM vw_delivered_orders AS o
    INNER JOIN customers AS c
        ON o.customer_id = c.customer_id
)
SELECT TOP 10
    customer_state,
    COUNT(order_id) AS total_orders,
    SUM(is_late) AS late_orders,
    CAST(SUM(is_late) * 100 / COUNT(order_id) AS DECIMAL(5,2)) AS late_delivery_pct
FROM delivery_flags
GROUP BY customer_state
ORDER BY late_delivery_pct DESC;

-- 10. Do late deliveries correlate with lower review scores?
WITH delivery_flags AS (
    SELECT
        o.order_id,
        CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                THEN 'Late'
            ELSE 'On Time'
        END AS delivery_status
    FROM vw_delivered_orders AS o
)
SELECT
    df.delivery_status,
    COUNT(r.review_id) AS total_reviews,
    AVG(CAST(r.review_score AS FLOAT)) AS avg_review_score
FROM delivery_flags AS df
INNER JOIN vw_reviews_deduped AS r
    ON df.order_id = r.order_id
GROUP BY df.delivery_status
ORDER BY avg_review_score DESC;