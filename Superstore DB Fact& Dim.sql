-- Create DB
CREATE DATABASE IF NOT EXISTS Sample_Superstore_WD;
USE Sample_Superstore_WD;

-- Drop if exists (for clean re-run)
DROP TABLE IF EXISTS fact_sales;
DROP TABLE IF EXISTS dim_product;
DROP TABLE IF EXISTS dim_customer;
DROP TABLE IF EXISTS dim_date;

-----------------------------------------------------
-- Customer Dimension Table
-----------------------------------------------------
CREATE TABLE dim_customer (
    customer_id VARCHAR(255) PRIMARY KEY,
    customer_name VARCHAR(255),
    segment VARCHAR(255),
    country VARCHAR(255),
    city VARCHAR(255),
    state VARCHAR(255),
    postal_code VARCHAR(255),
    region VARCHAR(255)
);

-----------------------------------------------------
-- Product Dimension Table
-----------------------------------------------------
CREATE TABLE dim_product (
    product_id VARCHAR(255) PRIMARY KEY,
    category VARCHAR(255),
    sub_category VARCHAR(255),
    product_name VARCHAR(255)
);

-----------------------------------------------------
-- Date Dimension Table
-- (We will fill it later after converting dates)
-----------------------------------------------------
CREATE TABLE dim_date (
    date_id DATE PRIMARY KEY,
    year INT,
    month INT,
    month_name VARCHAR(20),
    day INT,
    quarter INT
);

-----------------------------------------------------
-- Fact Table
-----------------------------------------------------
CREATE TABLE fact_sales (
    sales_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id VARCHAR(255),
    order_date DATE,
    ship_date DATE,
    delivery_days INT,
    customer_id VARCHAR(255),
    product_id VARCHAR(255),
    sales DECIMAL(10,2),
    quantity INT,
    discount DECIMAL(5,2),
    profit DECIMAL(10,2),

    FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    FOREIGN KEY (order_date) REFERENCES dim_date(date_id),
    FOREIGN KEY (ship_date) REFERENCES dim_date(date_id)
);

-----------------------------------------------------
-- Insert Data
-----------------------------------------------------
-- dim_customer
USE Sample_Superstore_WD;

INSERT IGNORE INTO dim_customer (customer_id, customer_name, segment, country, city, state, postal_code, region)
SELECT DISTINCT
  Custome_ID AS customer_id,
  Customer_Name AS customer_name,
  Segment,
  Country,
  City,
  State,
  Postal_Code,
  Region
FROM Sample_Superstore
WHERE Custome_ID IS NOT NULL AND Custome_ID <> '';

-- dim_product

INSERT IGNORE INTO dim_product (product_id, category, sub_category, product_name)
SELECT DISTINCT
  Product_ID AS product_id,
  Category,
  Sub_Category,
  Product_Name
FROM Sample_Superstore
WHERE Product_ID IS NOT NULL AND Product_ID <> '';


-- dim_shipmode
INSERT IGNORE INTO dim_shipmode (ship_mode_name)
SELECT DISTINCT
  Ship_Mode
FROM Sample_Superstore
WHERE Ship_Mode IS NOT NULL AND Ship_Mode <> '';

-- Check

SELECT 'dim_customer' AS tbl, COUNT(*) AS rows FROM dim_customer;
SELECT 'dim_product'  AS tbl, COUNT(*) AS rows FROM dim_product;
SELECT 'dim_shipmode' AS tbl, COUNT(*) AS rows FROM dim_shipmode;


SELECT customer_id, customer_name, segment FROM dim_customer LIMIT 10;
SELECT product_id, category, sub_category, product_name FROM dim_product LIMIT 10;
SELECT * FROM dim_shipmode LIMIT 10;

-- Fact_Sales

DROP TABLE IF EXISTS fact_sales;

CREATE TABLE fact_sales (
  sales_id INT AUTO_INCREMENT PRIMARY KEY,
  row_id VARCHAR(255),
  order_id VARCHAR(255),
  order_date DATE,
  ship_date DATE,
  delivery_days INT,
  ship_mode VARCHAR(100),
  customer_id VARCHAR(255),
  product_id VARCHAR(255),
  sales DECIMAL(14,2),
  quantity DECIMAL(12,3),
  discount DECIMAL(10,4),
  profit DECIMAL(14,2),
  order_year INT,
  order_month INT,
  order_day INT,
  order_weekday INT,
  region VARCHAR(100),
  category VARCHAR(150),
  sub_category VARCHAR(150)
);


INSERT INTO fact_sales (
  row_id, order_id, order_date, ship_date, delivery_days, ship_mode,
  customer_id, product_id, quantity, discount, sales, profit,
  order_year, order_month, order_day, order_weekday, region, category, sub_category
)
SELECT
  Row_ID,
  Order_ID,


  (CASE
     WHEN STR_TO_DATE(Order_Date, '%m/%d/%Y') IS NOT NULL THEN STR_TO_DATE(Order_Date, '%m/%d/%Y')
     WHEN STR_TO_DATE(Order_Date, '%Y-%m-%d') IS NOT NULL THEN STR_TO_DATE(Order_Date, '%Y-%m-%d')
     ELSE NULL
   END) AS order_date,

  (CASE
     WHEN STR_TO_DATE(Ship_Date, '%m/%d/%Y') IS NOT NULL THEN STR_TO_DATE(Ship_Date, '%m/%d/%Y')
     WHEN STR_TO_DATE(Ship_Date, '%Y-%m-%d') IS NOT NULL THEN STR_TO_DATE(Ship_Date, '%Y-%m-%d')
     ELSE NULL
   END) AS ship_date,


  (CASE
     WHEN
       (CASE WHEN STR_TO_DATE(Order_Date, '%m/%d/%Y') IS NOT NULL THEN STR_TO_DATE(Order_Date, '%m/%d/%Y')
             WHEN STR_TO_DATE(Order_Date, '%Y-%m-%d') IS NOT NULL THEN STR_TO_DATE(Order_Date, '%Y-%m-%d')
             ELSE NULL END) IS NOT NULL
     AND
       (CASE WHEN STR_TO_DATE(Ship_Date, '%m/%d/%Y') IS NOT NULL THEN STR_TO_DATE(Ship_Date, '%m/%d/%Y')
             WHEN STR_TO_DATE(Ship_Date, '%Y-%m-%d') IS NOT NULL THEN STR_TO_DATE(Ship_Date, '%Y-%m-%d')
             ELSE NULL END) IS NOT NULL
     THEN DATEDIFF(
       (CASE WHEN STR_TO_DATE(Ship_Date, '%m/%d/%Y') IS NOT NULL THEN STR_TO_DATE(Ship_Date, '%m/%d/%Y')
             WHEN STR_TO_DATE(Ship_Date, '%Y-%m-%d') IS NOT NULL THEN STR_TO_DATE(Ship_Date, '%Y-%m-%d')
             ELSE NULL END),
       (CASE WHEN STR_TO_DATE(Order_Date, '%m/%d/%Y') IS NOT NULL THEN STR_TO_DATE(Order_Date, '%m/%d/%Y')
             WHEN STR_TO_DATE(Order_Date, '%Y-%m-%d') IS NOT NULL THEN STR_TO_DATE(Order_Date, '%Y-%m-%d')
             ELSE NULL END)
     )
     ELSE NULL
   END) AS delivery_days,

  Ship_Mode AS ship_mode,
  Custome_ID AS customer_id,
  Product_ID AS product_id,


  CAST(NULLIF(REGEXP_REPLACE(Quantity, '[^0-9.-]', ''), '') AS DECIMAL(12,3)) AS quantity,


  CAST(NULLIF(REGEXP_REPLACE(Discount, '[^0-9.-]', ''), '') AS DECIMAL(10,4)) AS discount,

 
  CAST(NULLIF(REGEXP_REPLACE(Sales, '[^0-9.-]', ''), '') AS DECIMAL(14,2)) AS sales,
  CAST(NULLIF(REGEXP_REPLACE(Profit, '[^0-9.-]', ''), '') AS DECIMAL(14,2)) AS profit,


  (CASE WHEN (CASE WHEN STR_TO_DATE(Order_Date, '%m/%d/%Y') IS NOT NULL THEN STR_TO_DATE(Order_Date, '%m/%d/%Y')
                   WHEN STR_TO_DATE(Order_Date, '%Y-%m-%d') IS NOT NULL THEN STR_TO_DATE(Order_Date, '%Y-%m-%d')
                   ELSE NULL END) IS NOT NULL
        THEN YEAR((CASE WHEN STR_TO_DATE(Order_Date, '%m/%d/%Y') IS NOT NULL THEN STR_TO_DATE(Order_Date, '%m/%d/%Y')
                        WHEN STR_TO_DATE(Order_Date, '%Y-%m-%d') IS NOT NULL THEN STR_TO_DATE(Order_Date, '%Y-%m-%d')
                        ELSE NULL END))
        ELSE NULL END) AS order_year,

  (CASE WHEN (CASE WHEN STR_TO_DATE(Order_Date, '%m/%d/%Y') IS NOT NULL THEN STR_TO_DATE(Order_Date, '%m/%d/%Y')
                   WHEN STR_TO_DATE(Order_Date, '%Y-%m-%d') IS NOT NULL THEN STR_TO_DATE(Order_Date, '%Y-%m-%d')
                   ELSE NULL END) IS NOT NULL
        THEN MONTH((CASE WHEN STR_TO_DATE(Order_Date, '%m/%d/%Y') IS NOT NULL THEN STR_TO_DATE(Order_Date, '%m/%d/%Y')
                         WHEN STR_TO_DATE(Order_Date, '%Y-%m-%d') IS NOT NULL THEN STR_TO_DATE(Order_Date, '%Y-%m-%d')
                         ELSE NULL END))
        ELSE NULL END) AS order_month,

  (CASE WHEN (CASE WHEN STR_TO_DATE(Order_Date, '%m/%d/%Y') IS NOT NULL THEN STR_TO_DATE(Order_Date, '%m/%d/%Y')
                   WHEN STR_TO_DATE(Order_Date, '%Y-%m-%d') IS NOT NULL THEN STR_TO_DATE(Order_Date, '%Y-%m-%d')
                   ELSE NULL END) IS NOT NULL
        THEN DAY((CASE WHEN STR_TO_DATE(Order_Date, '%m/%d/%Y') IS NOT NULL THEN STR_TO_DATE(Order_Date, '%m/%d/%Y')
                         WHEN STR_TO_DATE(Order_Date, '%Y-%m-%d') IS NOT NULL THEN STR_TO_DATE(Order_Date, '%Y-%m-%d')
                         ELSE NULL END))
        ELSE NULL END) AS order_day,

  (CASE WHEN (CASE WHEN STR_TO_DATE(Order_Date, '%m/%d/%Y') IS NOT NULL THEN STR_TO_DATE(Order_Date, '%m/%d/%Y')
                   WHEN STR_TO_DATE(Order_Date, '%Y-%m-%d') IS NOT NULL THEN STR_TO_DATE(Order_Date, '%Y-%m-%d')
                   ELSE NULL END) IS NOT NULL
        THEN DAYOFWEEK((CASE WHEN STR_TO_DATE(Order_Date, '%m/%d/%Y') IS NOT NULL THEN STR_TO_DATE(Order_Date, '%m/%d/%Y')
                               WHEN STR_TO_DATE(Order_Date, '%Y-%m-%d') IS NOT NULL THEN STR_TO_DATE(Order_Date, '%Y-%m-%d')
                               ELSE NULL END))
        ELSE NULL END) AS order_weekday,

  Region AS region,
  Category AS category,
  Sub_Category AS sub_category

FROM Sample_Superstore
WHERE Order_ID IS NOT NULL AND Order_ID <> '';
