-- Row counts
SELECT 'dim_customer' AS table_name, COUNT(*) AS row_count FROM olist.dim_customer
UNION ALL SELECT 'dim_seller', COUNT(*) FROM olist.dim_seller
UNION ALL SELECT 'dim_product', COUNT(*) FROM olist.dim_product
UNION ALL SELECT 'fact_order', COUNT(*) FROM olist.fact_order
UNION ALL SELECT 'fact_order_item', COUNT(*) FROM olist.fact_order_item;

-- Missing unique customer IDs
SELECT COUNT(*) AS missing_customer_unique_id
FROM olist.dim_customer
WHERE customer_unique_id IS NULL OR BTRIM(customer_unique_id) = '';

-- Duplicate order IDs (should return no rows because order_id is a primary key)
SELECT order_id, COUNT(*) AS duplicate_count
FROM olist.fact_order
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Orphan checks (should return zero rows if foreign keys were applied correctly)
SELECT COUNT(*) AS items_without_order
FROM olist.fact_order_item i
LEFT JOIN olist.fact_order o USING (order_id)
WHERE o.order_id IS NULL;

SELECT COUNT(*) AS items_without_product
FROM olist.fact_order_item i
LEFT JOIN olist.dim_product p USING (product_id)
WHERE p.product_id IS NULL;

SELECT COUNT(*) AS items_without_seller
FROM olist.fact_order_item i
LEFT JOIN olist.dim_seller s USING (seller_id)
WHERE s.seller_id IS NULL;

-- Numeric consistency check: assumes gross_value = price + freight_value.
SELECT
    COUNT(*) AS item_rows,
    SUM(price) AS total_item_revenue,
    SUM(freight_value) AS total_freight,
    SUM(gross_value) AS total_gross_value,
    SUM(price + freight_value) AS calculated_gross_value,
    SUM(gross_value - price - freight_value) AS gross_value_difference
FROM olist.fact_order_item;

-- Date/timestamp sanity checks
SELECT COUNT(*) AS delivered_orders_missing_delivery_timestamp
FROM olist.fact_order
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

SELECT COUNT(*) AS negative_delivery_days
FROM olist.fact_order
WHERE delivery_days < 0;

-- Status distribution; canceled orders are intentionally included here.
SELECT order_status, COUNT(*) AS total_orders
FROM olist.fact_order
GROUP BY order_status
ORDER BY total_orders DESC;
