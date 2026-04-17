USE DataWarehouse

-- Gold Layer (Start Schema) 
IF OBJECT_ID ('gold.erp_order_TL', 'U') IS NOT NULL
	DROP TABLE gold.erp_order
SELECT * INTO gold.erp_order FROM silver.erp_order

IF OBJECT_ID ('gold.erp_order_items', 'U') IS NOT NULL
	DROP TABLE gold.erp_order_items;
SELECT * INTO gold.erp_order_items FROM silver.erp_order_items

IF OBJECT_ID ('gold.erp_product', 'U') IS NOT NULL
	DROP TABLE gold.erp_product;
SELECT * INTO gold.erp_product FROM silver.erp_product

IF OBJECT_ID ('gold.crm_customer', 'U') IS NOT NULL
	DROP TABLE gold.crm_customer;
SELECT * INTO gold.crm_customer FROM silver.crm_customer

------		Create Primary Key, Foreign Key		------
ALTER TABLE gold.erp_order
ALTER COLUMN order_id INT NOT NULL

ALTER TABLE gold.erp_order_items
ALTER COLUMN order_item_id INT NOT NULL

ALTER TABLE gold.erp_product
ALTER COLUMN product_id VARCHAR(50) NOT NULL

ALTER TABLE gold.crm_customer
ALTER COLUMN customer_id VARCHAR(50) NOT NULL

	----	 ==========		----

ALTER TABLE gold.erp_product
ADD CONSTRAINT PK_dim_erp_product PRIMARY KEY (product_id);

ALTER TABLE gold.crm_customer
ADD CONSTRAINT PK_dim_crm_customer PRIMARY KEY (customer_id);

ALTER TABLE gold.erp_order
ADD CONSTRAINT PK_fact_erp_order PRIMARY KEY (order_id),
	FOREIGN KEY (customer_id)
	REFERENCES gold.crm_customer(customer_id)

ALTER TABLE gold.erp_order_items
ADD CONSTRAINT PK_fact_order_items PRIMARY KEY (order_item_id),
	FOREIGN KEY (order_id)
	REFERENCES gold.erp_order(order_id), 
	FOREIGN KEY (product_id) 
	REFERENCES gold.erp_product(product_id);
