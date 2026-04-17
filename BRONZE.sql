-- Create Database 'DataWarehouse'
USE master;

CREATE DATABASE DataWarehouse;

USE DataWarehouse;

CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO

-- ==============================================================

-- Bronze Layer (Raw Data)
IF OBJECT_ID ('bronze.erp_order', 'U') IS NOT NULL
	DROP TABLE bronze.erp_order
CREATE TABLE bronze.erp_order (
	order_id INT,
	order_date DATE,
	customer_id VARCHAR(50),
	year_month CHAR(7),
	subtotal_amount DECIMAL(20, 2),
	shipping_fee_total DECIMAL(20, 2),
	commission_total DECIMAL(20, 2),
	maintenance_total DECIMAL(20, 2),
	total_amount DECIMAL(20, 2),
	campaign_id VARCHAR(50)
);

IF OBJECT_ID ('bronze.erp_order_items', 'U') IS NOT NULL
	DROP TABLE bronze.erp_order_items;
CREATE TABLE bronze.erp_order_items (
	order_item_id INT,
	order_id INT, 
	product_id VARCHAR(50),
	quantity SMALLINT,
	unit_price DECIMAL(20, 2),
	unit_price_after_discount DECIMAL(20, 2),
	line_total DECIMAL(20, 2),
	discount_percent DECIMAL(20, 2),
	commission_amount DECIMAL(20, 2),
	maintenance_amount DECIMAL(20, 2),
	shipping_fee_item DECIMAL(20, 2),
	estimated_delivery_start DATE,
	estimated_delivery_end DATE,
	item_status NVARCHAR(50),
	is_campaign BIT,
	product_campaign_id VARCHAR(50)
);

IF OBJECT_ID ('bronze.erp_product', 'U') IS NOT NULL
	DROP TABLE bronze.erp_product;
CREATE TABLE bronze.erp_product (
	product_id VARCHAR(50),
	seller_id VARCHAR(50),
	category NVARCHAR(50),
	product_name NVARCHAR(50),
	maintenance_rate DECIMAL(20, 3),
	commission_rate DECIMAL(20, 2),
	[weight] DECIMAL(20, 2),
	created_at DATE
);

IF OBJECT_ID ('bronze.crm_customer', 'U') IS NOT NULL
	DROP TABLE bronze.crm_customer;
CREATE TABLE bronze.crm_customer (
	customer_id VARCHAR(50),
	first_name NVARCHAR(50),
	last_name NVARCHAR(50),
	gender NVARCHAR(10),
	dob DATE,
	registration_date DATE,
	phone INT,
	email NVARCHAR(100),
	province NVARCHAR(50),
	city NVARCHAR(50)
);

-- ==============================================================

-- Bulk Insert CSV into Table 
TRUNCATE TABLE bronze.erp_order
BULK INSERT bronze.erp_order
FROM 'T:\DATA ANALYSIS\Project\shopee_TL\shopee_orders_thailand.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n',
	TABLOCK
);

TRUNCATE TABLE bronze.erp_order_items
BULK INSERT bronze.erp_order_items
FROM 'T:\DATA ANALYSIS\Project\shopee_TL\shopee_order_items_thailand.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n',
	TABLOCK
);

TRUNCATE TABLE bronze.erp_product
BULK INSERT bronze.erp_product
FROM 'T:\DATA ANALYSIS\Project\shopee_TL\shopee_products_thailand.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n',
	TABLOCK
);

TRUNCATE TABLE bronze.crm_customer
BULK INSERT bronze.crm_customer
FROM 'T:\DATA ANALYSIS\Project\shopee_TL\shopee_customers_thailand.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n',
	TABLOCK
);

-- ==============================================================
