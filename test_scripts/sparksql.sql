-- Setup Environment
drop database if exists raw CASCADE;
CREATE DATABASE IF NOT EXISTS raw;
USE raw;

-- 1. CLEANUP
DROP TABLE IF EXISTS raw.dim_products;
DROP TABLE IF EXISTS raw.dim_stores;
DROP TABLE IF EXISTS raw.fact_sales_bronze;

--------------------------------------------------------------------------------
-- 2. DIMENSION A: Products (50k rows)a
--------------------------------------------------------------------------------
CREATE TABLE raw.dim_products USING DELTA AS
SELECT 
    id as product_id,
    concat('Product_', CAST(id AS STRING)) as product_name,
    CASE WHEN id % 10 = 0 THEN 'Electronics' 
         WHEN id % 10 = 1 THEN 'Groceries' 
         ELSE 'Home & Garden' END as category,
    (rand() * 500) + 10 as price
FROM range(5000000);

--------------------------------------------------------------------------------
-- 3. DIMENSION B: Stores (1k rows)
--------------------------------------------------------------------------------
CREATE TABLE raw.dim_stores USING DELTA AS
SELECT 
    id as store_id,
    concat('Store_City_', CAST((id % 50) AS STRING)) as city,
    CASE WHEN id % 2 = 0 THEN 'Standard' ELSE 'Premium' END as store_tier
FROM range(100000);

--------------------------------------------------------------------------------
-- 4. FACT TABLE: Sales (2 Million rows - The Stressor)
-- 2M rows with joins will likely cause spilling to disk on 3.5GB nodes.
--------------------------------------------------------------------------------
CREATE TABLE raw.fact_sales_bronze (
    transaction_id STRING,
    product_id INT,
    store_id INT,
    sale_timestamp TIMESTAMP,
    quantity INT
) USING DELTA;

INSERT INTO raw.fact_sales_bronze
SELECT 
    uuid() as transaction_id,
    CAST(rand() * 50000 AS INT) as product_id,
    CAST(rand() * 1000 AS INT) as store_id,
    current_timestamp() - (id * interval 5 seconds) as sale_timestamp,
    CAST((rand() * 10) + 1 AS INT) as quantity
FROM range(10000000); 

--------------------------------------------------------------------------------
-- 5. THE ULTIMATE TEST: Gold Triple Join + Analytical Window
--------------------------------------------------------------------------------
-- This query:
-- 1. Joins 2M rows against 50k and 1k dimensions.
-- 2. Calculates Running Totals (Window Function) - extremely RAM intensive.
-- 3. Performs a multi-level aggregation.

CREATE TABLE raw.sales_analytics_gold USING DELTA AS
WITH enriched_sales AS (
    SELECT 
        s.sale_timestamp,
        p.category,
        p.product_name,
        st.city,
        (s.quantity * p.price) as revenue    
    FROM raw.fact_sales_bronze s
    JOIN raw.dim_products p ON s.product_id = p.product_id
    JOIN raw.dim_stores st ON s.store_id = st.store_id
),
daily_metrics AS (
    SELECT 
        to_date(sale_timestamp) as sale_date,
        city,
        category,
        sum(revenue) as daily_revenue,
        count(*) as transaction_count
    FROM enriched_sales
    GROUP BY 1, 2, 3
)
SELECT 
    *,
    -- This Window function will force a full shuffle of the daily_metrics
    sum(daily_revenue) OVER (PARTITION BY city, category ORDER BY sale_date) as running_total_revenue
FROM daily_metrics
ORDER BY city, sale_date DESC;