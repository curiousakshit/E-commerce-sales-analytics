CREATE TABLE customers (
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INTEGER,
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);

SELECT *
FROM customers
LIMIT 0;

DROP TABLE customers;

CREATE TABLE customers (
    customer_id TEXT,
    customer_unique_id TEXT,
    customer_zip_code_prefix INTEGER,
    customer_city TEXT,
    customer_state TEXT
);

CREATE TABLE orders (
    order_id TEXT,
    customer_id TEXT,
    order_status TEXT,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
);
ALTER TABLE orders
ADD delivery_days TEXT;
ALTER TABLE orders
DROP delivery_days;

ALTER TABLE orders
ADD COLUMN purchase_year TEXT,
ADD COLUMN purchase_month TEXT,
ADD COLUMN purchase_day TEXT,
ADD COLUMN delivery_days TEXT;

CREATE TABLE products (
    product_id TEXT,
    product_category_name TEXT,
    product_name_lenght NUMERIC,
    product_description_lenght NUMERIC,
    product_photos_qty NUMERIC,
    product_weight_g NUMERIC,
    product_length_cm NUMERIC,
    product_height_cm NUMERIC,
    product_width_cm NUMERIC
);

CREATE TABLE order_items (
    order_id TEXT,
    order_item_id INTEGER,
    product_id TEXT,
    seller_id TEXT,
    shipping_limit_date TIMESTAMP,
    price NUMERIC,
    freight_value NUMERIC
);

CREATE TABLE payments (
    order_id TEXT,
    payment_sequential INTEGER,
    payment_type TEXT,
    payment_installments INTEGER,
    payment_value NUMERIC
);

CREATE TABLE reviews (
    review_id TEXT,
    order_id TEXT,
    review_score INTEGER,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

ALTER TABLE reviews 
DROP review_comment_title,
DROP review_comment_message;
	 
SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM order_items;
SELECT COUNT(*) FROM payments;
SELECT COUNT(*) FROM reviews;

SELECT ROUND(SUM(payment_value),2)AS Total_Revenue FROM payments

SELECT COUNT(*) AS Total_Orders
FROM orders

SELECT COUNT(DISTINCT customer_id)
FROM customers;

SELECT payment_type, ROUND(SUM(payment_value),2) AS Total_Revenue FROM payments
GROUP BY payment_type
ORDER BY Total_Revenue DESC;

SELECT
order_status,
COUNT(*) total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

SELECT c.customer_state, ROUND(SUM(p.payment_value),2) AS Revenue FROM customers as c
INNER JOIN orders as o on c.customer_id = o.customer_id
INNER JOIN payments as p on o.order_id = p.order_id
GROUP BY c.customer_state
ORDER BY Revenue DESC

SELECT
pr.product_category_name,
ROUND(SUM(p.payment_value),2) revenue
FROM products pr
JOIN order_items oi
ON pr.product_id = oi.product_id
JOIN payments p
ON oi.order_id = p.order_id
GROUP BY pr.product_category_name
ORDER BY revenue DESC
LIMIT 10;

SELECT o.purchase_month, ROUND(SUM(payment_value),2) monthly_revenue
FROM orders o
JOIN payments p on o.order_id = p.order_id
GROUP BY o.purchase_month 
Order BY monthly_revenue DESC

SELECT AVG(
    DATE_PART(
        'day',
        order_delivered_customer_date - order_purchase_timestamp
    )
)
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;

CREATE VIEW sales_summary AS
SELECT
o.order_id,
c.customer_state,
p.payment_type,
p.payment_value
FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id
JOIN payments p
ON o.order_id = p.order_id;

CREATE VIEW monthly_revenue AS
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    ROUND(SUM(p.payment_value),2) AS revenue
FROM orders o
JOIN payments p
ON o.order_id = p.order_id
GROUP BY month
ORDER BY month;

CREATE VIEW state_revenue AS
SELECT
    c.customer_state,
    ROUND(SUM(p.payment_value),2) AS revenue,
    COUNT(DISTINCT c.customer_id) AS customers
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
JOIN payments p
ON o.order_id = p.order_id
GROUP BY c.customer_state;

CREATE VIEW delivery_performance AS
SELECT
    order_id,
    customer_id,
    order_status,
    delivery_days
FROM orders
WHERE delivery_days IS NOT NULL;

CREATE OR REPLACE VIEW review_analysis AS
SELECT
    review_score,
    COUNT(*) AS total_reviews
FROM reviews
GROUP BY review_score
ORDER BY review_score;

CREATE OR REPLACE VIEW top_customers AS
SELECT
    o.customer_id,
    ROUND(SUM(p.payment_value),2) AS total_spent,
    COUNT(o.order_id) AS total_orders
FROM orders o
JOIN payments p
ON o.order_id = p.order_id
GROUP BY o.customer_id;

CREATE OR REPLACE VIEW category_revenue AS
SELECT
    pr.product_category_name,
    ROUND(SUM(p.payment_value),2) AS revenue
FROM products pr
JOIN order_items oi
ON pr.product_id = oi.product_id
JOIN payments p
ON oi.order_id = p.order_id
GROUP BY pr.product_category_name;

SELECT * FROM sales_summary LIMIT 10;

SELECT * FROM monthly_revenue;

SELECT * FROM category_revenue
ORDER BY revenue DESC
LIMIT 10;

SELECT * FROM state_revenue
ORDER BY revenue DESC;

SELECT * FROM delivery_performance
LIMIT 10;

SELECT * FROM review_analysis;

SELECT * FROM top_customers
ORDER BY total_spent DESC
LIMIT 10;

WITH state_revenue AS
(
    SELECT
        c.customer_state,
        SUM(p.payment_value) AS revenue
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN payments p
        ON o.order_id = p.order_id
    GROUP BY c.customer_state
)

SELECT *
FROM state_revenue
ORDER BY revenue DESC;

SELECT
    c.customer_state,
    SUM(p.payment_value) AS revenue,
    RANK() OVER(
        ORDER BY SUM(p.payment_value) DESC
    ) AS revenue_rank
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN payments p
    ON o.order_id = p.order_id
GROUP BY c.customer_state;

SELECT
    c.customer_state,
    SUM(p.payment_value) AS revenue,
    DENSE_RANK() OVER(
        ORDER BY SUM(p.payment_value) DESC
    ) AS revenue_rank
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN payments p
    ON o.order_id = p.order_id
GROUP BY c.customer_state;

WITH customer_sales AS
(
    SELECT
        c.customer_state,
        o.customer_id,
        SUM(p.payment_value) AS total_sales,
        ROW_NUMBER() OVER(
            PARTITION BY c.customer_state
            ORDER BY SUM(p.payment_value) DESC
        ) AS rn
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN payments p
        ON o.order_id = p.order_id
    GROUP BY
        c.customer_state,
        o.customer_id
)

SELECT *
FROM customer_sales
WHERE rn = 1;

WITH monthly_revenue AS
(
    SELECT
        purchase_year,
        purchase_month,
        SUM(payment_value) revenue
    FROM sales_summary
    GROUP BY
        purchase_year,
        purchase_month
)

SELECT
    *,
    LAG(revenue) OVER(
        ORDER BY purchase_year,purchase_month
    ) AS previous_month_revenue
FROM monthly_revenue; 