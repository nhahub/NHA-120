-- Over View Page
-- total sales , profit , profit margin

SELECT 
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    (SUM(profit) / SUM(sales)* 100) AS profit_margin_percent
FROM fact_sales;

-- total quantity sold 

SELECT 
    SUM(quantity) AS total_quantity_sold
FROM fact_sales;

-- average discount

SELECT 
    round(AVG(discount)*100,2) AS average_discount_percent
FROM fact_sales;
 
 ---------------------------------
 -- Regional Performance
 
 -- Profit by Region

SELECT 
    c.region,
    SUM(f.sales) AS total_sales,
    SUM(f.profit) AS total_profit,
    (SUM(f.profit) / SUM(f.sales) * 100) AS profit_margin_percent
FROM
    fact_sales f
        JOIN
    dim_customer c USING (customer_id)
GROUP BY c.region
ORDER BY total_sales DESC;

-- Sales by State

SELECT 
    c.state AS State, SUM(f.sales) AS Total_Sales
FROM
    fact_sales f
        JOIN
    dim_customer c USING (customer_id)
GROUP BY c.state
ORDER BY total_sales DESC;

--------------------------- 
-- Customer Analytics
 -- Average Order Value (AOV)
SELECT 
    SUM(sales) / COUNT(DISTINCT order_id) AS avg_order_value
FROM fact_sales;
 -- CLV (Customer Lifetime Value)
SELECT 
    customer_id,
    SUM(sales) AS total_sales
FROM fact_sales
GROUP BY customer_id;
 -- Top Customers
SELECT 
    customer_id,
    SUM(sales) AS total_sales,
    COUNT(DISTINCT order_id) AS total_orders
FROM fact_sales
GROUP BY customer_id
ORDER BY total_sales DESC
LIMIT 10;	
-----------------------
-- Operational Insights
-- Average Delivery Time (Overall) by Days
SELECT 
    ROUND(AVG(delivery_days), 2) AS avg_delivery_days
FROM fact_sales;

-- Average Delivery Time per Ship Mode 
SELECT 
    s.ship_mode_name,
    ROUND(AVG(f.delivery_days), 2) AS avg_delivery_days
FROM fact_sales f
JOIN dim_shipmode s 
    ON f.ship_mode = s.ship_mode_name
GROUP BY s.ship_mode_name
ORDER BY avg_delivery_days;


-- C. Average Delivery Time by Month

SELECT 
    order_year,
    order_month,
    ROUND(AVG(delivery_days), 2) AS avg_delivery_days
FROM fact_sales
GROUP BY order_year, order_month
ORDER BY order_year, order_month;


-- 🚚 2. Ship Mode Performance (Orders / Sales / Profit / Average Delivery)

-- This evaluates how each shipping mode contributes to sales, orders, and profit.

-- 1). Ship Mode Summary

SELECT 
    s.ship_mode_name,
    COUNT(DISTINCT f.order_id) AS total_orders,
    ROUND(COALESCE(SUM(f.sales),0),2) AS total_sales,
    ROUND(COALESCE(SUM(f.profit),0),2) AS total_profit,
    ROUND(AVG(f.delivery_days),2) AS avg_delivery_days
FROM fact_sales f
JOIN dim_shipmode s 
    ON f.ship_mode = s.ship_mode_name
GROUP BY s.ship_mode_name
ORDER BY total_sales DESC;



-- 2) Ship Mode Performance by Region

SELECT 
    c.region,
    s.ship_mode_name,
    COUNT(DISTINCT f.order_id) AS total_orders,
    ROUND(COALESCE(SUM(f.sales),0),2) AS total_sales,
    ROUND(COALESCE(SUM(f.profit),0),2) AS total_profit,
    ROUND(AVG(f.delivery_days),2) AS avg_delivery_days
FROM fact_sales f
JOIN dim_customer c 
    ON f.customer_id = c.customer_id
JOIN dim_shipmode s 
    ON f.ship_mode = s.ship_mode_name
GROUP BY c.region, s.ship_mode_name
ORDER BY c.region, total_sales DESC;

-- 3) Ship Mode Share of Total Sales (% of Total)
SELECT 
    s.ship_mode_name,
    ROUND(SUM(f.sales),2) AS total_sales,
    CONCAT(ROUND(SUM(f.sales) * 100 / NULLIF((SELECT SUM(sales) FROM fact_sales),0),2), '%') AS pct_of_total_sales
FROM fact_sales f
JOIN dim_shipmode s 
    ON f.ship_mode = s.ship_mode_name
GROUP BY s.ship_mode_name
ORDER BY total_sales DESC;

