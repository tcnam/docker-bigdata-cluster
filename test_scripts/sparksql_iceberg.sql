-- Setup Environment
DROP DATABASE IF EXISTS raw CASCADE;
CREATE DATABASE raw;
USE raw;

--------------------------------------------------------------------------------
-- 1. CLEANUP
--------------------------------------------------------------------------------
DROP TABLE IF EXISTS raw.dim_products;
DROP TABLE IF EXISTS raw.dim_stores;
DROP TABLE IF EXISTS raw.fact_sales_bronze;
DROP TABLE IF EXISTS raw.sales_analytics_gold;

--------------------------------------------------------------------------------
-- 2. DIMENSION A: Products (50k rows)
--------------------------------------------------------------------------------
CREATE TABLE raw.dim_products
USING ICEBERG AS
SELECT
    id AS product_id,
    CONCAT('Product_', CAST(id AS STRING)) AS product_name,
    CASE
        WHEN id % 10 = 0 THEN 'Electronics'
        WHEN id % 10 = 1 THEN 'Groceries'
        ELSE 'Home & Garden'
    END AS category,
    (RAND() * 500) + 10 AS price
FROM range(50000);

--------------------------------------------------------------------------------
-- 3. DIMENSION B: Stores (1k rows)
--------------------------------------------------------------------------------
CREATE TABLE raw.dim_stores
USING ICEBERG AS
SELECT
    id AS store_id,
    CONCAT('Store_City_', CAST(id % 50 AS STRING)) AS city,
    CASE
        WHEN id % 2 = 0 THEN 'Standard'
        ELSE 'Premium'
    END AS store_tier
FROM range(1000);

--------------------------------------------------------------------------------
-- 4. FACT TABLE: Sales (10 Million rows)
--------------------------------------------------------------------------------
CREATE TABLE raw.fact_sales_bronze (
    transaction_id STRING,
    product_id BIGINT,
    store_id BIGINT,
    sale_timestamp TIMESTAMP,
    quantity INT
) USING ICEBERG;

INSERT INTO raw.fact_sales_bronze
SELECT
    UUID() AS transaction_id,
    CAST(RAND() * 50000 AS BIGINT) AS product_id,
    CAST(RAND() * 1000 AS BIGINT) AS store_id,
    current_timestamp() - (id * INTERVAL 5 SECONDS) AS sale_timestamp,
    CAST((RAND() * 10) + 1 AS INT) AS quantity
FROM range(10000000);

--------------------------------------------------------------------------------
-- 5. GOLD TABLE: Triple Join + Analytical Window
--------------------------------------------------------------------------------
CREATE TABLE raw.sales_analytics_gold
USING ICEBERG AS
WITH enriched_sales AS (
    SELECT
        s.sale_timestamp,
        p.category,
        p.product_name,
        st.city,
        (s.quantity * p.price) AS revenue
    FROM raw.fact_sales_bronze s
    INNER JOIN raw.dim_products p
        ON s.product_id = p.product_id
    INNER JOIN raw.dim_stores st
        ON s.store_id = st.store_id
),
daily_metrics AS (
    SELECT
        TO_DATE(sale_timestamp) AS sale_date,
        city,
        category,
        SUM(revenue) AS daily_revenue,
        COUNT(*) AS transaction_count
    FROM enriched_sales
    GROUP BY
        TO_DATE(sale_timestamp),
        city,
        category
)
SELECT
    *,
    SUM(daily_revenue) OVER (
        PARTITION BY city, category
        ORDER BY sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_revenue
FROM daily_metrics
ORDER BY city, sale_date DESC;