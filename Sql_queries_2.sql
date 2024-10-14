-- Select all columns from each table
SELECT * FROM customer_details;
SELECT * FROM exchange_details;
SELECT * FROM product_details;
SELECT * FROM sales_details;
SELECT * FROM stores_details;

-- Describe tables
-- Change dtypes to date
-- customer table
--\d customer_details;
SELECT column_name, data_type, character_maximum_length
FROM information_schema.columns
WHERE table_name = 'customer_details';
UPDATE customer_details SET Birthday = TO_DATE(Birthday::TEXT, 'YYYY-MM-DD');
ALTER TABLE customer_details
ALTER COLUMN Birthday TYPE DATE USING Birthday::DATE;

-- sales table
--\d sales_details;
SELECT column_name, data_type, character_maximum_length
FROM information_schema.columns
WHERE table_name = 'sales_details';
UPDATE sales_details SET Order_Date = TO_DATE(Order_Date::TEXT, 'YYYY-MM-DD');
ALTER TABLE sales_details
ALTER COLUMN Order_Date TYPE DATE USING Order_Date::DATE;

-- stores table
--\d stores_details;
SELECT column_name, data_type, character_maximum_length
FROM information_schema.columns
WHERE table_name = 'stores_details';
UPDATE stores_details SET Open_Date = TO_DATE(Open_Date::TEXT, 'YYYY-MM-DD');
ALTER TABLE stores_details
ALTER COLUMN Open_Date TYPE DATE USING Open_Date::DATE;

-- exchange rate table
UPDATE exchange_details SET Date = TO_DATE(Date::TEXT, 'YYYY-MM-DD');
ALTER TABLE exchange_details
ALTER COLUMN Date TYPE DATE USING Date::DATE;

UPDATE stores_details SET Open_Date = TO_DATE(Open_Date::TEXT, 'YYYY-MM-DD');
ALTER TABLE stores_details
ALTER COLUMN Open_Date TYPE DATE USING Open_Date::DATE;

-- queries to get insights from 5 tables
-- 1. Overall female count
SELECT COUNT(Gender) AS Female_count
FROM customer_details
WHERE Gender = 'Female';

-- 2. Overall male count
SELECT COUNT(Gender) AS Male_count
FROM customer_details
WHERE Gender = 'Male';

-- 3. Count of customers in country-wise
SELECT sd.Country, COUNT(DISTINCT c.CustomerKey) AS customer_count
FROM sales_details c
JOIN stores_details sd ON c.StoreKey = sd.StoreKey
GROUP BY sd.Country
ORDER BY customer_count DESC;

-- 4. Overall count of customers
SELECT COUNT(DISTINCT s.CustomerKey) AS customer_count
FROM sales_details s;

-- 5. Count of stores in country-wise
SELECT Country, COUNT(StoreKey) AS store_count
FROM stores_details
GROUP BY Country
ORDER BY store_count DESC;

-- 6. Store-wise sales
SELECT s.StoreKey, sd.Country, SUM(Unit_Price_USD * s.Quantity) AS total_sales_amount
FROM product_details pd
JOIN sales_details s ON pd.ProductKey = s.ProductKey
JOIN stores_details sd ON s.StoreKey = sd.StoreKey
GROUP BY s.StoreKey, sd.Country;

-- 7. Overall selling amount
SELECT SUM(Unit_Price_USD * sd.Quantity) AS total_sales_amount
FROM product_details pd
JOIN sales_details sd ON pd.ProductKey = sd.ProductKey;

-- 8. CP and SP difference and profit
SELECT 
    Product_name, 
    Unit_price_USD, 
    Unit_Cost_USD, 
    ROUND(CAST(Unit_price_USD - Unit_Cost_USD AS numeric), 2) AS diff,
    ROUND(CAST((Unit_price_USD - Unit_Cost_USD) / Unit_Cost_USD * 100 AS numeric), 2) AS profit
FROM 
    product_details;

-- 9. Brand-wise selling amount
SELECT 
    Brand, 
    ROUND(CAST(SUM(Unit_price_USD * sd.Quantity) AS numeric), 2) AS sales_amount
FROM 
    product_details pd
JOIN 
    sales_details sd ON pd.ProductKey = sd.ProductKey
GROUP BY 
    Brand;

-- 10. Subcategory-wise selling amount
SELECT Subcategory, COUNT(Subcategory) AS subcategory_count
FROM product_details
GROUP BY Subcategory;

SELECT 
    Subcategory, 
    ROUND(CAST(SUM(Unit_price_USD * sd.Quantity) AS numeric), 2) AS TOTAL_SALES_AMOUNT
FROM 
    product_details pd
JOIN 
    sales_details sd ON pd.ProductKey = sd.ProductKey
GROUP BY 
    Subcategory
ORDER BY 
    TOTAL_SALES_AMOUNT DESC;

-- 11. Country-wise overall sales
SELECT s.Country, SUM(pd.Unit_price_USD * sd.Quantity) AS total_sales
FROM product_details pd
JOIN sales_details sd ON pd.ProductKey = sd.ProductKey
JOIN stores_details s ON sd.StoreKey = s.StoreKey
GROUP BY s.Country;

SELECT s.Country, COUNT(DISTINCT s.StoreKey), SUM(pd.Unit_price_USD * sd.Quantity) AS total_sales
FROM product_details pd
JOIN sales_details sd ON pd.ProductKey = sd.ProductKey
JOIN stores_details s ON sd.StoreKey = s.StoreKey
GROUP BY s.Country;

-- 12. Year-wise brand sales
SELECT 
    EXTRACT(YEAR FROM Order_Date) AS order_year, 
    pd.Brand, 
    ROUND(CAST(SUM(Unit_price_USD * sd.Quantity) AS numeric), 2) AS year_sales
FROM 
    sales_details sd
JOIN 
    product_details pd ON sd.ProductKey = pd.ProductKey
GROUP BY 
    EXTRACT(YEAR FROM Order_Date), 
    pd.Brand;

-- 13. Overall sales with quantity
SELECT Brand, SUM(Unit_Price_USD * sd.Quantity) AS sp, SUM(Unit_Cost_USD * sd.Quantity) AS cp,
       (SUM(Unit_Price_USD * sd.Quantity) - SUM(Unit_Cost_USD * sd.Quantity)) / SUM(Unit_Cost_USD * sd.Quantity) * 100 AS profit
FROM product_details pd
JOIN sales_details sd ON sd.ProductKey = pd.ProductKey
GROUP BY Brand;

-- 14. Month-wise sales with quantity
SELECT DATE_TRUNC('month', Order_Date) AS month, SUM(Unit_Price_USD * sd.Quantity) AS sp_month
FROM sales_details sd
JOIN product_details pd ON sd.ProductKey = pd.ProductKey
GROUP BY DATE_TRUNC('month', Order_Date);

-- 15. Month and year-wise sales with quantity
SELECT 
    DATE_TRUNC('month', Order_Date) AS month, 
    EXTRACT(YEAR FROM Order_Date) AS year, 
    pd.Brand, 
    SUM(Unit_Price_USD * sd.Quantity) AS sp_month
FROM 
    sales_details sd
JOIN 
    product_details pd ON sd.ProductKey = pd.ProductKey
GROUP BY 
    DATE_TRUNC('month', Order_Date), 
    EXTRACT(YEAR FROM Order_Date), 
    pd.Brand;

-- 16. Year-wise sales
SELECT 
    EXTRACT(YEAR FROM Order_Date) AS year, 
    SUM(Unit_Price_USD * sd.Quantity) AS sp_year
FROM 
    sales_details sd
JOIN 
    product_details pd ON sd.ProductKey = pd.ProductKey
GROUP BY 
    EXTRACT(YEAR FROM Order_Date);

-- 17. Comparing current month and previous month
WITH monthly_sales AS (
    SELECT DATE_TRUNC('month', Order_Date) AS month, SUM(Unit_Price_USD * sd.Quantity) AS sales
    FROM sales_details sd
    JOIN product_details pd ON sd.ProductKey = pd.ProductKey
    GROUP BY DATE_TRUNC('month', Order_Date)
)
SELECT month, sales, LAG(sales) OVER (ORDER BY month) AS Previous_Month_Sales
FROM monthly_sales;

-- 18. Comparing current year and previous year sales
WITH yearly_sales AS (
    SELECT 
        EXTRACT(YEAR FROM Order_Date) AS year, 
        SUM(Unit_Price_USD * sd.Quantity) AS sales
    FROM 
        sales_details sd
    JOIN 
        product_details pd ON sd.ProductKey = pd.ProductKey
    GROUP BY 
        EXTRACT(YEAR FROM Order_Date)
)
SELECT 
    year, 
    sales, 
    LAG(sales) OVER (ORDER BY year) AS Previous_Year_Sales
FROM 
    yearly_sales;

-- 19. Month-wise profit
WITH monthly_profit AS (
    SELECT 
        DATE_TRUNC('month', Order_Date) AS month, 
        SUM(Unit_Price_USD * sd.Quantity) - SUM(Unit_Cost_USD * sd.Quantity) AS profit
    FROM 
        sales_details sd
    JOIN 
        product_details pd ON sd.ProductKey = pd.ProductKey
    GROUP BY 
        DATE_TRUNC('month', Order_Date)
)
SELECT 
    month, 
    profit, 
    LAG(profit) OVER (ORDER BY month) AS Previous_Month_Profit,
    ROUND(((CAST(profit AS numeric) - CAST(LAG(profit) OVER (ORDER BY month) AS numeric)) / CAST(LAG(profit) OVER (ORDER BY month) AS numeric)) * 100, 2) AS profit_percent
FROM 
    monthly_profit;

-- 20. Year-wise profit
WITH yearly_profit AS (
    SELECT DATE_PART('year', Order_Date) AS year, 
           SUM(Unit_Price_USD * sd.Quantity) - SUM(Unit_Cost_USD * sd.Quantity) AS profit
    FROM sales_details sd
    JOIN product_details pd ON sd.ProductKey = pd.ProductKey
    GROUP BY DATE_PART('year', Order_Date)
)
SELECT year, profit, LAG(profit) OVER (ORDER BY year) AS Previous_Year_Profit,
       ROUND(((CAST(profit AS numeric) - CAST(LAG(profit) OVER (ORDER BY year) AS numeric)) / CAST(LAG(profit) OVER (ORDER BY year) AS numeric)) * 100, 2) AS profit_percent
FROM yearly_profit;