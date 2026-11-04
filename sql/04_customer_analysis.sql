-- Customer counts: all dimension records vs unique customers
SELECT
    COUNT(*) AS customer_id_rows,
    COUNT(DISTINCT customer_unique_id) AS unique_customers,
    COUNT(*) FILTER (WHERE customer_unique_id IS NULL) AS rows_missing_unique_id
FROM olist.dim_customer;

-- Revenue and order count per unique customer
SELECT
    dc.customer_unique_id,
    COUNT(DISTINCT fo.order_id) AS total_orders,
    SUM(foi.price) AS revenue
FROM olist.fact_order fo
JOIN olist.fact_order_item foi ON foi.order_id = fo.order_id
JOIN olist.dim_customer dc ON dc.customer_id = fo.customer_id
WHERE fo.order_status <> 'canceled'
  AND dc.customer_unique_id IS NOT NULL
GROUP BY dc.customer_unique_id
ORDER BY revenue DESC;

-- Repeat-customer metrics based on distinct non-canceled orders
WITH customer_orders AS (
    SELECT dc.customer_unique_id, COUNT(DISTINCT fo.order_id) AS order_count
    FROM olist.fact_order fo
    JOIN olist.dim_customer dc ON dc.customer_id = fo.customer_id
    WHERE fo.order_status <> 'canceled'
      AND dc.customer_unique_id IS NOT NULL
    GROUP BY dc.customer_unique_id
)
SELECT
    COUNT(*) AS customers_with_qualifying_orders,
    COUNT(*) FILTER (WHERE order_count > 1) AS repeat_customers,
    COUNT(*) FILTER (WHERE order_count = 1) AS one_time_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE order_count > 1)
          / NULLIF(COUNT(*), 0), 2) AS repeat_customer_rate_pct
FROM customer_orders;

-- Customer revenue bands; edit thresholds if the business definition differs.
WITH customer_revenue AS (
    SELECT dc.customer_unique_id, SUM(foi.price) AS revenue
    FROM olist.fact_order fo
    JOIN olist.fact_order_item foi ON foi.order_id = fo.order_id
    JOIN olist.dim_customer dc ON dc.customer_id = fo.customer_id
    WHERE fo.order_status <> 'canceled'
      AND dc.customer_unique_id IS NOT NULL
    GROUP BY dc.customer_unique_id
)
SELECT
    CASE
        WHEN revenue < 100 THEN '0-99.99'
        WHEN revenue < 500 THEN '100-499.99'
        WHEN revenue < 1000 THEN '500-999.99'
        ELSE '1000+'
    END AS revenue_band,
    COUNT(*) AS customers
FROM customer_revenue
GROUP BY 1
ORDER BY MIN(revenue);
