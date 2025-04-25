-- database
USE ordersdb;

-- see if any tables exist
SHOW TABLES;

-- create a new table named df_orders
CREATE TABLE df_orders (
    order_id INT PRIMARY KEY,
    order_date DATE,
    ship_mode VARCHAR(20),
    segment VARCHAR(20),
    country VARCHAR(20),
    city VARCHAR(20),
    state VARCHAR(20),
    postal_code VARCHAR(20),
    region VARCHAR(20),
    category VARCHAR(20),
    sub_category VARCHAR(20),
    product_id VARCHAR(50),
    quantity INT,
    discount DECIMAL(7,2),
    sale_price DECIMAL(7,2),
    profit DECIMAL(7,2)
);

-- check the new table 
SELECT * FROM df_orders;

-- check the table after importing data from python
SELECT * FROM df_orders;

-- find the top 10 highest revenue generating products
SELECT product_id, SUM(sale_price * quantity) AS sales
FROM df_orders
GROUP BY product_id
ORDER BY sales DESC
LIMIT 10;

-- find top 5 highest selling products in each region
SELECT DISTINCT region FROM df_orders;

-- method 1
WITH cte AS 
	(
	SELECT region, product_id, SUM(sale_price * quantity) AS sales
	FROM df_orders
	GROUP BY region, product_id
)
SELECT * FROM 
	(
	SELECT *, RANK() OVER(PARTITION BY region ORDER BY sales DESC) AS rn
	FROM cte) a
WHERE rn <= 5;

-- method 2
SELECT * FROM (
	SELECT region, product_id, SUM(sale_price* quantity) AS sales, RANK() OVER(PARTITION BY region ORDER BY SUM(sale_price* quantity) DESC) AS rn
	FROM df_orders
	GROUP BY region, product_id) AS ranked
WHERE rn <= 5;

-- find month over month growth comparison for 2022 and 2023 sales eg: Jan 2022 vs Jan 2023
WITH cte AS (
	SELECT YEAR(order_date) AS order_year, MONTH(order_date) AS order_month, SUM(sale_price* quantity) AS sales
	FROM df_orders
	GROUP BY order_year, order_month)
SELECT order_month,
SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END) AS 'order_year = 2022',
SUM(CASE WHEN order_year = 2023 THEN sales ELSE 0 END) AS 'order_year = 2023'
FROM cte
GROUP BY order_month
ORDER BY order_month ASC;

-- for each category which month had highest sales

-- method 1
WITH cte AS 
	(
	SELECT category, DATE_FORMAT(order_date, '%Y-%m') AS month_year, SUM(sale_price* quantity) AS sales
	FROM df_orders
	GROUP BY category, month_year)
SELECT * FROM
(SELECT *, RANK() OVER(PARTITION BY category ORDER BY sales DESC) AS rn
FROM cte) a
WHERE rn = 1;

-- method 2
SELECT * FROM
	(
	SELECT category, DATE_FORMAT(order_date, '%Y-%m') AS month_year, SUM(sale_price* quantity) AS sales, RANK() OVER(PARTITION BY category ORDER BY SUM(sale_price* quantity) DESC) AS rn
	FROM df_orders
    GROUP BY category, month_year
) cte
WHERE rn = 1;

-- Which sub-category has the highest growth profit in 2023 compare to 2022
WITH cte AS
	(
	SELECT sub_category, YEAR(order_date) AS order_year, SUM(profit* quantity) AS total_profit
	FROM df_orders
	GROUP BY sub_category, order_year
	)
, cte2 AS
	(
    SELECT sub_category,
	SUM(CASE WHEN order_year = 2022 THEN total_profit ELSE 0 END) AS profit_2022,
	SUM(CASE WHEN order_year = 2023 THEN total_profit ELSE 0 END) AS profit_2023
	FROM cte
    GROUP BY sub_category
    )
SELECT sub_category, ROUND(100 * (profit_2023 - profit_2022) / profit_2022 ,2) AS profit_growth
FROM cte2
ORDER BY profit_growth DESC;