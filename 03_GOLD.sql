-- Gold Layer (Start Schema) 
/* ============================================================
   03_gold.sql : Gold layer (Normalized model / ERD)
   Tables: customers, products, campaigns, orders, order_items
   View:   vw_sales_detail (flat view for analysis)
   Run after 02_silver.sql
   ============================================================ */
USE DataWarehouse;

------ 0. Drop: view first, then child tables, then parent tables
IF OBJECT_ID('gold.order_items', 'U') IS NOT NULL DROP TABLE gold.order_items;
IF OBJECT_ID('gold.orders',      'U') IS NOT NULL DROP TABLE gold.orders;
IF OBJECT_ID('gold.campaigns',   'U') IS NOT NULL DROP TABLE gold.campaigns;
IF OBJECT_ID('gold.products',    'U') IS NOT NULL DROP TABLE gold.products;
IF OBJECT_ID('gold.customers',   'U') IS NOT NULL DROP TABLE gold.customers;

------ 1. Create tables (PK/FK declared in the DDL) ------------
-- Parent tables first
CREATE TABLE gold.customers (
    customer_id       VARCHAR(50)  NOT NULL CONSTRAINT PK_customers PRIMARY KEY,
    first_name        NVARCHAR(50),
    last_name         NVARCHAR(50),
    gender            NVARCHAR(10),
    dob               DATE,
    registration_date DATE,
    phone             VARCHAR(20),
    email             NVARCHAR(100),
    province          NVARCHAR(50),
    city              NVARCHAR(50)
);

CREATE TABLE gold.products (
    product_id       VARCHAR(50)  NOT NULL CONSTRAINT PK_products PRIMARY KEY,
    category         NVARCHAR(50),
    product_name     NVARCHAR(50),
    maintenance_rate DECIMAL(20,3),
    commission_rate  DECIMAL(20,2),
    [weight]         DECIMAL(20,2),
    created_at       DATE
);

CREATE TABLE gold.campaigns (
    campaign_id   VARCHAR(50)  NOT NULL CONSTRAINT PK_campaigns PRIMARY KEY,
    campaign_name NVARCHAR(100),
    [start_date]    DATE,
    end_date      DATE,
    campaign_type VARCHAR(50)
);

-- Child tables
CREATE TABLE gold.orders (
    order_id           INT          NOT NULL CONSTRAINT PK_orders PRIMARY KEY,
    order_date         DATE,
    customer_id        VARCHAR(50)  NOT NULL
        CONSTRAINT FK_orders_customers REFERENCES gold.customers(customer_id),
    year_month         CHAR(7),
    subtotal_amount    DECIMAL(20,2),
    shipping_fee_total DECIMAL(20,2),
    commission_total   DECIMAL(20,2),
    maintenance_total  DECIMAL(20,2),
    total_amount       DECIMAL(20,2),
    campaign_id        VARCHAR(50)  NOT NULL   -- 'None' = order has no campaign
        CONSTRAINT FK_orders_campaigns REFERENCES gold.campaigns(campaign_id)
);

CREATE TABLE gold.order_items (
    order_item_id             INT          NOT NULL CONSTRAINT PK_order_items PRIMARY KEY,
    order_id                  INT          NOT NULL
        CONSTRAINT FK_order_items_orders    REFERENCES gold.orders(order_id),
    product_id                VARCHAR(50)  NOT NULL
        CONSTRAINT FK_order_items_products  REFERENCES gold.products(product_id),
    quantity                  SMALLINT,
    unit_price                DECIMAL(20,2),
    unit_price_after_discount DECIMAL(20,2),
    line_total                DECIMAL(20,2),
    discount_percent          DECIMAL(20,2),
    commission_amount         DECIMAL(20,2),
    maintenance_amount        DECIMAL(20,2),
    shipping_fee_item         DECIMAL(20,2),
    estimated_delivery_start  DATE,
    estimated_delivery_end    DATE,
    item_status               NVARCHAR(50),
    is_campaign               BIT,
    product_campaign_id       VARCHAR(50)  NOT NULL   -- 'None' = product has no campaign
        CONSTRAINT FK_order_items_campaigns REFERENCES gold.campaigns(campaign_id)
);
GO

------ 2. Orphan checks: stop early with a clear message --------
---- Without these, the FK would fail halfway with a hard-to-read error.
-- orders -> customers
SELECT DISTINCT o.customer_id
FROM silver.erp_order AS o
LEFT JOIN silver.crm_customer AS c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL;

-- order_items -> orders
SELECT DISTINCT i.order_id
FROM silver.erp_order_items AS i
LEFT JOIN silver.erp_order AS o ON o.order_id = i.order_id
WHERE o.order_id IS NULL;

-- order_items -> products
SELECT DISTINCT i.product_id
FROM silver.erp_order_items AS i
LEFT JOIN silver.erp_product AS p ON p.product_id = i.product_id
WHERE p.product_id IS NULL;

-- orders -> campaigns
SELECT DISTINCT o.campaign_id
FROM silver.erp_order AS o
LEFT JOIN silver.crm_campaign AS c ON c.campaign_id = o.campaign_id
WHERE c.campaign_id IS NULL;

-- order_items -> campaigns
SELECT DISTINCT i.product_campaign_id
FROM silver.erp_order_items AS i
LEFT JOIN silver.crm_campaign AS c ON c.campaign_id = i.product_campaign_id
WHERE i.product_campaign_id <> 'None' AND c.campaign_id IS NULL;

------ 3. Load: parent tables first, child tables after ---------
INSERT INTO gold.customers
    (customer_id, first_name, last_name, gender, dob, registration_date,
     phone, email, province, city)
SELECT customer_id, first_name, last_name, gender, dob, registration_date,
       phone, email, province, city
FROM silver.crm_customer;

INSERT INTO gold.products
    (product_id, category, product_name, maintenance_rate, commission_rate, [weight], created_at)
SELECT product_id, category, product_name, maintenance_rate, commission_rate, [weight], created_at
FROM silver.erp_product;

INSERT INTO gold.campaigns
    (campaign_id, campaign_name, [start_date], end_date, campaign_type)
SELECT campaign_id, campaign_name, [start_date], end_date, campaign_type
FROM silver.crm_campaign;

-- Placeholder row for orders / items that have no campaign
-- (skipped automatically if the source already contains 'None')
IF NOT EXISTS (SELECT * FROM gold.campaigns WHERE campaign_id = 'None')
    INSERT INTO gold.campaigns (campaign_id, campaign_name, campaign_type)
    VALUES ('None', 'No campaign', 'None');

INSERT INTO gold.orders
    (order_id, order_date, customer_id, year_month, subtotal_amount,
     shipping_fee_total, commission_total, maintenance_total, total_amount, campaign_id)
SELECT order_id, order_date, customer_id, year_month, subtotal_amount,
       shipping_fee_total, commission_total, maintenance_total, total_amount, campaign_id
FROM silver.erp_order;

INSERT INTO gold.order_items
    (order_item_id, order_id, product_id, quantity, unit_price, unit_price_after_discount,
     line_total, discount_percent, commission_amount, maintenance_amount, shipping_fee_item,
     estimated_delivery_start, estimated_delivery_end, item_status, is_campaign, product_campaign_id)
SELECT order_item_id, order_id, product_id, quantity, unit_price, unit_price_after_discount,
       line_total, discount_percent, commission_amount, maintenance_amount, shipping_fee_item,
       estimated_delivery_start, estimated_delivery_end, item_status, is_campaign, product_campaign_id
FROM silver.erp_order_items;
GO

------ 4. Checks after load -------------------------------------
-- Row counts: Silver vs Gold (the 'None' placeholder is excluded)
SELECT 'customers' AS customers,
       (SELECT COUNT(*) FROM silver.crm_customer) AS silver_rows,
       (SELECT COUNT(*) FROM gold.customers)      AS gold_rows
UNION ALL
SELECT 'products' AS products,
       (SELECT COUNT(*) FROM silver.erp_product),
       (SELECT COUNT(*) FROM gold.products)
UNION ALL
SELECT 'campaigns' AS campaigns,
       (SELECT COUNT(*) FROM silver.crm_campaign WHERE campaign_id <> 'None'),
       (SELECT COUNT(*) FROM gold.campaigns      WHERE campaign_id <> 'None')
UNION ALL
SELECT 'orders' AS orders,
       (SELECT COUNT(*) FROM silver.erp_order),
       (SELECT COUNT(*) FROM gold.orders)
UNION ALL
SELECT 'order_items' AS order_items,
       (SELECT COUNT(*) FROM silver.erp_order_items),
       (SELECT COUNT(*) FROM gold.order_items)
