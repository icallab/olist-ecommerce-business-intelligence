-- Payment type distribution and payment value
SELECT
    payment_type,
    COUNT(*) AS payment_records,
    COUNT(DISTINCT order_id) AS orders,
    SUM(payment_value) AS total_payment_value,
    ROUND(100.0 * SUM(payment_value)
          / NULLIF(SUM(SUM(payment_value)) OVER (), 0), 2) AS payment_value_share_pct
FROM olist.fact_order_payment
GROUP BY payment_type
ORDER BY total_payment_value DESC;

-- Payment installments
SELECT
    payment_installments,
    COUNT(*) AS payment_records,
    SUM(payment_value) AS total_payment_value
FROM olist.fact_order_payment
GROUP BY payment_installments
ORDER BY payment_installments;

-- Payment total vs item/freight totals by order.
-- Payment value may differ because of vouchers, installments, and dataset definitions.
WITH payment_by_order AS (
    SELECT order_id, SUM(payment_value) AS payment_value
    FROM olist.fact_order_payment
    GROUP BY order_id
),
items_by_order AS (
    SELECT order_id, SUM(price) AS item_revenue, SUM(freight_value) AS freight_value,
           SUM(gross_value) AS gross_value
    FROM olist.fact_order_item
    GROUP BY order_id
)
SELECT
    COUNT(*) AS matched_orders,
    SUM(p.payment_value) AS total_payment_value,
    SUM(i.item_revenue) AS total_item_revenue,
    SUM(i.freight_value) AS total_freight_value,
    SUM(i.gross_value) AS total_gross_value,
    SUM(p.payment_value - i.gross_value) AS payment_minus_gross
FROM payment_by_order p
JOIN items_by_order i ON i.order_id = p.order_id;

-- Review score distribution
SELECT
    review_score,
    COUNT(*) AS review_count,
    ROUND(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS review_share_pct
FROM olist.fact_order_review
GROUP BY review_score
ORDER BY review_score;

-- Average review score by delivery lateness; delivered order data only
SELECT
    CASE WHEN fo.is_late = 1 THEN 'Late'
         WHEN fo.is_late = 0 THEN 'On time'
         ELSE 'Unknown'
    END AS delivery_status,
    COUNT(*) AS review_records,
    ROUND(AVG(r.review_score::numeric), 2) AS average_review_score
FROM olist.fact_order_review r
JOIN olist.fact_order fo ON fo.order_id = r.order_id
WHERE r.review_score BETWEEN 1 AND 5
GROUP BY 1
ORDER BY 1;
