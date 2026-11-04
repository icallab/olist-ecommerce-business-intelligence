-- Overall delivery KPIs for delivered orders only
SELECT
    ROUND(AVG(delivery_days), 2) AS avg_delivery_days,
    ROUND(100.0 * AVG(is_late::numeric), 2) AS late_delivery_rate_pct,
    COUNT(*) AS delivered_orders
FROM olist.fact_order
WHERE order_status = 'delivered';

-- Delivery and lateness by customer state
SELECT
    dc.customer_state,
    COUNT(DISTINCT fo.order_id) AS delivered_orders,
    ROUND(AVG(fo.delivery_days), 2) AS avg_delivery_days,
    ROUND(100.0 * AVG(fo.is_late::numeric), 2) AS late_delivery_rate_pct
FROM olist.fact_order fo
JOIN olist.dim_customer dc ON dc.customer_id = fo.customer_id
WHERE fo.order_status = 'delivered'
GROUP BY dc.customer_state
ORDER BY late_delivery_rate_pct DESC NULLS LAST;

-- Order status distribution; include all statuses
SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS order_share_pct
FROM olist.fact_order
GROUP BY order_status
ORDER BY total_orders DESC;

-- Recalculate delivery days and late flag for comparison.
-- Timestamp date-level comparison is used for late flag; adapt if your project uses exact timestamps.
SELECT
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND order_delivered_customer_date IS NOT NULL
          AND order_purchase_timestamp IS NOT NULL
    ) AS delivered_with_timestamps,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp)) / 86400.0
    ) FILTER (
        WHERE order_status = 'delivered'
          AND order_delivered_customer_date IS NOT NULL
          AND order_purchase_timestamp IS NOT NULL
    ), 2) AS recalculated_avg_delivery_days,
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND order_delivered_customer_date::date > order_estimated_delivery_date::date
    ) AS recalculated_late_orders
FROM olist.fact_order;
