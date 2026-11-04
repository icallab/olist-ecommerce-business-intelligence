CREATE DATABASE olist_bi;

CREATE SCHEMA olist;

CREATE TABLE olist.dim_customer (
    customer_id VARCHAR PRIMARY KEY,
    customer_unique_id VARCHAR,
    customer_zip_code INT,
    customer_city VARCHAR,
    customer_state VARCHAR
);

CREATE TABLE olist.dim_seller (
    seller_id VARCHAR PRIMARY KEY,
    seller_zip_code INT,
    seller_city VARCHAR,
    seller_state VARCHAR
);

CREATE TABLE olist.dim_product (
    product_id VARCHAR PRIMARY KEY,
    product_category_name VARCHAR,
    product_category_name_english VARCHAR,
    product_weight_g NUMERIC,
    product_length_cm NUMERIC,
    product_height_cm NUMERIC,
    product_width_cm NUMERIC
);

CREATE TABLE olist.dim_date (
    date DATE PRIMARY KEY,
    year INT,
    quarter VARCHAR,
    month INT,
    month_name VARCHAR,
    year_month VARCHAR,
    week INT,
    day INT,
    day_name VARCHAR
);

CREATE TABLE olist.fact_order (
    order_id VARCHAR PRIMARY KEY,
    customer_id VARCHAR,
    order_status VARCHAR,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    delivery_days NUMERIC,
    estimated_delay_days NUMERIC,
    is_late INT,
    order_purchase_date DATE,
    order_delivered_date DATE,
    CONSTRAINT fk_order_customer
        FOREIGN KEY (customer_id) REFERENCES olist.dim_customer(customer_id)
);

CREATE TABLE olist.fact_order_item (
    order_id VARCHAR,
    order_item_id INT,
    product_id VARCHAR,
    seller_id VARCHAR,
    shipping_limit_date TIMESTAMP,
    price NUMERIC,
    freight_value NUMERIC,
    gross_value NUMERIC,
    CONSTRAINT pk_fact_order_item PRIMARY KEY (order_id, order_item_id),
    CONSTRAINT fk_item_order FOREIGN KEY (order_id) REFERENCES olist.fact_order(order_id),
    CONSTRAINT fk_item_product FOREIGN KEY (product_id) REFERENCES olist.dim_product(product_id),
    CONSTRAINT fk_item_seller FOREIGN KEY (seller_id) REFERENCES olist.dim_seller(seller_id)
);

CREATE TABLE olist.fact_order_payment (
    order_id VARCHAR,
    payment_sequential INT,
    payment_type VARCHAR,
    payment_installments INT,
    payment_value NUMERIC,
    PRIMARY KEY (order_id, payment_sequential),
    CONSTRAINT fk_payment_order FOREIGN KEY (order_id) REFERENCES olist.fact_order(order_id)
);


CREATE TABLE olist.fact_order_review (
    review_id VARCHAR PRIMARY KEY,
    order_id VARCHAR,
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    CONSTRAINT fk_review_order FOREIGN KEY (order_id) REFERENCES olist.fact_order(order_id)
);

