USE DataWarehouse

-- Silver Layer (Data Cleaning)

------	Table: erp_order_TL		----------------
IF OBJECT_ID ('silver.erp_order', 'U') IS NOT NULL
	DROP TABLE silver.erp_order
SELECT * INTO silver.erp_order FROM bronze.erp_order

---- Check for duplicates by order_date: 
SELECT [Year], [Month]
	, COUNT (order_id) AS Unique_order
	, COUNT (*) AS Total_orders
	, COUNT (*) - COUNT (order_id) AS duplicate
FROM (
	SELECT order_id,
		YEAR(order_date) AS [Year], MONTH(order_date) AS [Month]
	FROM silver.erp_order
	) AS [Date]
GROUP BY [Year], [Month]
ORDER BY [Year] ASC, [Month] ASC

---- Check for NULL: 
DECLARE @NULL NVARCHAR(MAX) = '';
SELECT @NULL = @NULL + 
	', SUM(CASE WHEN [' + COLUMN_NAME + '] IS NULL THEN 1 ELSE 0 END) AS [' + COLUMN_NAME + ']'
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'erp_order' AND TABLE_SCHEMA = 'silver';
SET @NULL = 'SELECT ' + STUFF(@NULL, 1, 2, '') + 'FROM [silver].[erp_order]'
EXEC sp_executesql @NULL;

------	Table: erp_shopee_order_items_TL	----------------
IF OBJECT_ID ('silver.erp_order_items', 'U') IS NOT NULL
	DROP TABLE silver.erp_order_items;
SELECT * INTO silver.erp_order_items FROM bronze.erp_order_items

---- Check for dupdicates by item_status: 
SELECT item_status
	, COUNT (DISTINCT order_item_id) AS Unique_order_item_id
	, COUNT (*) AS Total_order_item_id
	, COUNT (DISTINCT CASE WHEN quantity > 0 THEN order_item_id END) AS Unique_quantity
FROM silver.erp_order_items
GROUP BY item_status

---- Check for NULL: 
DECLARE @NULL NVARCHAR(MAX) = '';
SELECT @NULL = @NULL + 
	', SUM(CASE WHEN [' + COLUMN_NAME + '] IS NULL THEN 1 ELSE 0 END) AS [' + COLUMN_NAME + ']' 
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'erp_order_items' AND TABLE_SCHEMA = 'silver';
SET @NULL = 'SELECT ' + STUFF(@NULL, 1, 2, '') + ' FROM [silver].[erp_order_items]';
EXEC sp_executesql @NULL;

UPDATE silver.erp_order_items
SET product_campaign_id = 'None'
WHERE product_campaign_id IS NULL;

------	Table: erp_shopee_product_TL	----------------
IF OBJECT_ID ('silver.erp_product', 'U') IS NOT NULL
	DROP TABLE silver.erp_product;
SELECT * INTO silver.erp_product FROM bronze.erp_product

---- Check for dupdicates: 
SELECT COUNT (DISTINCT product_id) AS Unique_product_id
	, COUNT (*) AS Total_product_id
FROM silver.erp_product

SELECT category, product_name
	, COUNT(DISTINCT product_id) AS Number_products 
FROM silver.erp_product
GROUP BY category, product_name
ORDER BY category ASC, product_name ASC

---- Check for NULL: 
DECLARE @NULL NVARCHAR(MAX) = '';
SELECT @NULL = @NULL + 
	', SUM(CASE WHEN [' + COLUMN_NAME + '] IS NULL THEN 1 ELSE 0 END) AS [' + COLUMN_NAME + ']' 
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'erp_product' AND TABLE_SCHEMA = 'silver';
SET @NULL = 'SELECT ' + STUFF(@NULL, 1, 2, '') + ' FROM [silver].[erp_product]';
EXEC sp_executesql @NULL;

------	Table: crm_shopee_customer_TL	----------------
IF OBJECT_ID ('silver.crm_customer', 'U') IS NOT NULL
	DROP TABLE silver.crm_customer
SELECT * INTO silver.crm_customer FROM bronze.crm_customer

---- Check for dupdicates by gender: 
SELECT gender
	, COUNT (DISTINCT customer_id) AS Unique_order_item_id
	, COUNT (*) AS Total_order_item_id
FROM silver.crm_customer
GROUP BY gender

SELECT DISTINCT province, city
	, COUNT(customer_id) AS Number_customers 
FROM silver.crm_customer
GROUP BY province, city
ORDER BY province ASC, city ASC

---- Check for NULL: 
DECLARE @NULL NVARCHAR(MAX) = '';
SELECT @NULL = @NULL + 
	', SUM(CASE WHEN [' + COLUMN_NAME + '] IS NULL THEN 1 ELSE 0 END) AS [' + COLUMN_NAME + ']' 
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'crm_customer' AND TABLE_SCHEMA = 'silver';
SET @NULL = 'SELECT ' + STUFF(@NULL, 1, 2, '') + ' FROM [silver].[crm_customer]';
EXEC sp_executesql @NULL;

---- Remove spaces: 
UPDATE silver.crm_customer
SET first_name = TRIM(first_name),
	last_name = TRIM(last_name)

-- ==============================================================

	------		Data Mining		------
SELECT SUM(total_amount) AS Total FROM silver.erp_order

SELECT category, product_name
	, SUM (total_amount) AS Total_amount
	, SUM (ITEMS.quantity)
FROM silver.erp_order AS ORDERS
LEFT JOIN silver.erp_order_items AS ITEMS
	ON ORDERS.order_id = ITEMS.order_id
LEFT JOIN silver.erp_product AS PRODUCTS
	ON ITEMS.product_id = PRODUCTS.product_id
GROUP BY category, product_name
ORDER BY category ASC, Total_amount DESC

WITH province_city_sales AS (
	SELECT province, city
		, SUM (total_amount) AS Total_amount
	FROM silver.erp_order AS ORDERS
	LEFT JOIN silver.crm_customer AS CUSTOMERS
		ON ORDERS.customer_id = CUSTOMERS.customer_id
	GROUP BY province, city
)
SELECT province, city, Total_amount
	,CAST (ROUND(Total_amount * 100 / SUM(Total_amount) OVER (), 2) AS DECIMAL(10, 2)) AS Amount_rate
FROM province_city_sales
ORDER BY Amount_rate DESC
