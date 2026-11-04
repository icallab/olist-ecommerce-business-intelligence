-- Core KPIs
SELECT
    COUNT(DISTINCT fo.order_id) AS total_orders,
    COUNT(DISTINCT dc.customer_unique_id) AS unique_customers,
    SUM(foi.price) AS total_revenue,
    SUM(foi.gross_value) AS total_gross_value,
    SUM(foi.price) / NULLIF(COUNT(DISTINCT fo.order_id), 0) AS average_order_value
FROM olist.fact_order fo
JOIN olist.fact_order_item foi ON foi.order_id = fo.order_id
JOIN olist.dim_customer dc ON dc.customer_id = fo.customer_id
WHERE fo.order_status <> 'canceled';

-- Monthly revenue and order count
SELECT
    DATE_TRUNC('month', fo.order_purchase_timestamp)::date AS month,
    SUM(foi.price) AS revenue,
    COUNT(DISTINCT fo.order_id) AS orders
FROM olist.fact_order fo
JOIN olist.fact_order_item foi ON foi.order_id = fo.order_id
WHERE fo.order_status <> 'canceled'
GROUP BY 1
ORDER BY 1;

-- Monthly AOV
SELECT
    DATE_TRUNC('month', fo.order_purchase_timestamp)::date AS month,
    SUM(foi.price) / NULLIF(COUNT(DISTINCT fo.order_id), 0) AS aov
FROM olist.fact_order fo
JOIN olist.fact_order_item foi ON foi.order_id = fo.order_id
WHERE fo.order_status <> 'canceled'
GROUP BY 1
ORDER BY 1;

-- Month-over-month revenue growth
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', fo.order_purchase_timestamp)::date AS month,
        SUM(foi.price) AS revenue
    FROM olist.fact_order fo
    JOIN olist.fact_order_item foi ON foi.order_id = fo.order_id
    WHERE fo.order_status <> 'canceled'
    GROUP BY 1
),
with_previous AS (
    SELECT month, revenue, LAG(revenue) OVER (ORDER BY month) AS previous_month_revenue
    FROM monthly_sales
)
SELECT
    month, revenue, previous_month_revenue,
    ROUND(100.0 * (revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0), 2) AS mom_growth_pct
FROM with_previous
ORDER BY month;

-- Top 10 categories by revenue
SELECT
    COALESCE(dp.product_category_name_english, 'Unknown') AS category,
    SUM(foi.price) AS revenue,
    COUNT(DISTINCT foi.order_id) AS orders,
    COUNT(*) AS items_sold
FROM olist.fact_order_item foi
JOIN olist.dim_product dp ON dp.product_id = foi.product_id
JOIN olist.fact_order fo ON fo.order_id = foi.order_id
WHERE fo.order_status <> 'canceled'
GROUP BY 1
ORDER BY revenue DESC
LIMIT 10;

-- Revenue share by category (share is calculated over all non-canceled category revenue)
WITH category_sales AS (
    SELECT
        COALESCE(dp.product_category_name_english, 'Unknown') AS category,
        SUM(foi.price) AS revenue
    FROM olist.fact_order_item foi
    JOIN olist.dim_product dp ON dp.product_id = foi.product_id
    JOIN olist.fact_order fo ON fo.order_id = foi.order_id
    WHERE fo.order_status <> 'canceled'
    GROUP BY 1
)
SELECT category, revenue,
       ROUND(100.0 * revenue / NULLIF(SUM(revenue) OVER (), 0), 2) AS revenue_share_pct
FROM category_sales
ORDER BY revenue DESC;

-- Average sales per seller; sellers with no qualifying sales are not included.
WITH seller_revenue AS (
    SELECT foi.seller_id, SUM(foi.price) AS revenue
    FROM olist.fact_order_item foi
    JOIN olist.fact_order fo ON fo.order_id = foi.order_id
    WHERE fo.order_status <> 'canceled'
    GROUP BY foi.seller_id
)
SELECT COUNT(*) AS sellers_with_sales,
       SUM(revenue) AS total_revenue,
       AVG(revenue) AS average_sales_per_seller,
       MIN(revenue) AS lowest_seller_revenue,
       MAX(revenue) AS highest_seller_revenue
FROM seller_revenue;

-- Top sellers by revenue
SELECT
    ds.seller_id, ds.seller_state,
    COUNT(DISTINCT foi.order_id) AS total_orders,
    SUM(foi.price) AS revenue,
    AVG(foi.price) AS avg_item_price
FROM olist.fact_order_item foi
JOIN olist.dim_seller ds ON ds.seller_id = foi.seller_id
JOIN olist.fact_order fo ON fo.order_id = foi.order_id
WHERE fo.order_status <> 'canceled'
GROUP BY ds.seller_id, ds.seller_state
ORDER BY revenue DESC
LIMIT 20;

-- Seller revenue ranking and cumulative revenue share, consistent canceled-order filter
WITH seller_revenue AS (
    SELECT foi.seller_id, SUM(foi.price) AS revenue
    FROM olist.fact_order_item foi
    JOIN olist.fact_order fo ON fo.order_id = foi.order_id
    WHERE fo.order_status <> 'canceled'
    GROUP BY foi.seller_id
),
ranked AS (
    SELECT seller_id, revenue,
           RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
           SUM(revenue) OVER (
               ORDER BY revenue DESC
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ) AS cumulative_revenue,
           SUM(revenue) OVER () AS total_revenue
    FROM seller_revenue
)
SELECT seller_id, revenue, revenue_rank,
       ROUND(100.0 * cumulative_revenue / NULLIF(total_revenue, 0), 2) AS cumulative_revenue_pct
FROM ranked
ORDER BY revenue_rank;
