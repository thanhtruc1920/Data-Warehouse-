USE DataWarehouse

-- Silver Layer (Data Cleaning)
------	Table: erp_order_TL		----------------
IF OBJECT_ID ('silver.erp_order', 'U') IS NOT NULL DROP TABLE silver.erp_order;
SELECT
    order_id,
    order_date,
    TRIM(customer_id)                                  AS customer_id,
    year_month,
    subtotal_amount,
    shipping_fee_total,
    commission_total,
    maintenance_total,
    total_amount,
	ISNULL(NULLIF(TRIM(campaign_id), ''), 'None')      AS campaign_id,
    SYSDATETIME()                                      AS dwh_create_date
INTO silver.erp_order
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_date DESC) AS rn
    FROM bronze.erp_order
    WHERE order_id IS NOT NULL
) AS order_rn
WHERE rn = 1;

------	Table: erp_shopee_order_items_TL	----------------
IF OBJECT_ID ('silver.erp_order_items', 'U') IS NOT NULL DROP TABLE silver.erp_order_items;
SELECT
    order_item_id,
    order_id,
    TRIM(product_id)                                   AS product_id,
    quantity,
    unit_price,
    unit_price_after_discount,
    line_total,
    discount_percent,
    commission_amount,
    maintenance_amount,
    shipping_fee_item,
    estimated_delivery_start,
    estimated_delivery_end,
    -- ' DELIVERED ' / 'delivered' -> 'Delivered'
    CASE WHEN NULLIF(TRIM(item_status), '') IS NULL THEN 'Unknown'
         ELSE UPPER(LEFT(TRIM(item_status), 1)) + LOWER(SUBSTRING(TRIM(item_status), 2, 50))
    END													  AS item_status,
    is_campaign,
    ISNULL(NULLIF(TRIM(product_campaign_id), ''), 'None') AS product_campaign_id,
    SYSDATETIME()										  AS dwh_create_date
INTO silver.erp_order_items
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY order_item_id ORDER BY (SELECT NULL)) AS rn
    FROM bronze.erp_order_items
    WHERE order_item_id IS NOT NULL
) AS order_items_rn
WHERE rn = 1;

UPDATE silver.erp_order_items
SET product_campaign_id = 'None'
WHERE product_campaign_id IS NULL;

------	Table: erp_shopee_product_TL	----------------
IF OBJECT_ID ('silver.erp_product', 'U') IS NOT NULL DROP TABLE silver.erp_product;
SELECT
    TRIM(product_id)                                   AS product_id,
    ISNULL(NULLIF(TRIM(category), ''), 'Unknown')      AS category,
    ISNULL(NULLIF(TRIM(product_name), ''), 'Unknown')  AS product_name,
    maintenance_rate,
    commission_rate,
    [weight],
    created_at,
    SYSDATETIME()                                      AS dwh_create_date
INTO silver.erp_product
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY TRIM(product_id) ORDER BY created_at DESC) AS rn
    FROM bronze.erp_product
    WHERE NULLIF(TRIM(product_id), '') IS NOT NULL
) AS product_rn
WHERE rn = 1;

------	Table: crm_shopee_customer_TL	----------------
IF OBJECT_ID ('silver.crm_customer', 'U') IS NOT NULL DROP TABLE silver.crm_customer;
SELECT
    TRIM(customer_id)                                  AS customer_id,
    TRIM(first_name)                                   AS first_name,
    TRIM(last_name)                                    AS last_name,
    CASE UPPER(TRIM(gender))
        WHEN 'M'      THEN 'Male'
        WHEN 'MALE'   THEN 'Male'
        WHEN 'F'      THEN 'Female'
        WHEN 'FEMALE' THEN 'Female'
        WHEN 'OTHER'  THEN 'Other'
        ELSE 'Unknown'
    END                                                AS gender,
    CASE WHEN dob > CAST(GETDATE() AS DATE) OR dob < '1900-01-01'
         THEN NULL ELSE dob END                        AS dob,
    registration_date,
    NULLIF(TRIM(phone), '')                            AS phone,
    LOWER(NULLIF(TRIM(email), ''))                     AS email,
    ISNULL(NULLIF(TRIM(province), ''), 'Unknown')      AS province,
    ISNULL(NULLIF(TRIM(city), ''), 'Unknown')          AS city,
    SYSDATETIME()                                      AS dwh_create_date
INTO silver.crm_customer
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY TRIM(customer_id) ORDER BY registration_date DESC) AS rn
    FROM bronze.crm_customer
    WHERE NULLIF(TRIM(customer_id), '') IS NOT NULL
) AS crm_customer_rn
WHERE rn = 1;

------	Table: crm_shopee_campaigns_TL	----------------
IF OBJECT_ID('silver.crm_campaign', 'U') IS NOT NULL DROP TABLE silver.crm_campaign;
SELECT
    TRIM(campaign_id)                                    AS campaign_id,
    ISNULL(NULLIF(TRIM(campaign_name), ''), 'Unknown')   AS campaign_name,
    [start_date],
    end_date,
    ISNULL(NULLIF(TRIM(campaign_type), ''), 'Unknown')   AS campaign_type,
    SYSDATETIME()                                        AS dwh_create_date
INTO silver.crm_campaign
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY TRIM(campaign_id) ORDER BY [start_date] DESC) AS rn
    FROM bronze.crm_campaign
    WHERE NULLIF(TRIM(campaign_id), '') IS NOT NULL
) AS crm_campaign_rn
WHERE rn = 1;

-- ==============================================================
	------		Data Quality Checks	-------
-- 1. Compare line numbers: Bronze -> Silver
---- removed_rows = rows dropped (duplicate key or missing key)
SELECT 'erp_order' AS table_name,
       (SELECT COUNT(*) FROM bronze.erp_order) AS bronze_rows,
       (SELECT COUNT(*) FROM silver.erp_order) AS silver_rows,
       (SELECT COUNT(*) FROM bronze.erp_order) - (SELECT COUNT(*) FROM silver.erp_order)
UNION ALL
SELECT 'erp_order_items',
       (SELECT COUNT(*) FROM bronze.erp_order_items) AS bronze_rows,
       (SELECT COUNT(*) FROM silver.erp_order_items) AS silver_rows,
       (SELECT COUNT(*) FROM bronze.erp_order_items) - (SELECT COUNT(*) FROM silver.erp_order_items)
UNION ALL
SELECT 'erp_product',
       (SELECT COUNT(*) FROM bronze.erp_product) AS bronze_rows,
       (SELECT COUNT(*) FROM silver.erp_product) AS silver_rows,
       (SELECT COUNT(*) FROM bronze.erp_product) - (SELECT COUNT(*) FROM silver.erp_product)
UNION ALL
SELECT 'crm_customer',
       (SELECT COUNT(*) FROM bronze.crm_customer) AS bronze_rows,
       (SELECT COUNT(*) FROM silver.crm_customer) AS silver_rows,
       (SELECT COUNT(*) FROM bronze.crm_customer) - (SELECT COUNT(*) FROM silver.crm_customer)

-- 2. Rules that should return 0 (violations > 0 needs investigation)
SELECT 'duplicate order_id' AS check_name, COUNT(*) AS violations
FROM (SELECT order_id FROM silver.erp_order GROUP BY order_id HAVING COUNT(*) > 1) AS ord_dup
UNION ALL
SELECT 'duplicate order_item_id', COUNT(*)
FROM (SELECT order_item_id FROM silver.erp_order_items GROUP BY order_item_id HAVING COUNT(*) > 1) AS item_dup
UNION ALL
SELECT 'duplicate product_id', COUNT(*)
FROM (SELECT product_id FROM silver.erp_product GROUP BY product_id HAVING COUNT(*) > 1) AS pro_dup
UNION ALL
SELECT 'duplicate customer_id', COUNT(*)
FROM (SELECT customer_id FROM silver.crm_customer GROUP BY customer_id HAVING COUNT(*) > 1) AS cus_dup
UNION ALL
SELECT 'duplicate campaign_id', COUNT(*)
FROM (SELECT campaign_id FROM silver.crm_campaign GROUP BY campaign_id HAVING COUNT(*) > 1) AS cam_dup
UNION ALL
SELECT 'orphan: order -> customer', COUNT(*)
FROM silver.erp_order AS o
LEFT JOIN silver.crm_customer AS c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL
UNION ALL
SELECT 'orphan: item -> order', COUNT(*)
FROM silver.erp_order_items AS i
LEFT JOIN silver.erp_order AS o ON o.order_id = i.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'orphan: item -> product', COUNT(*)
FROM silver.erp_order_items AS i
LEFT JOIN silver.erp_product AS p ON p.product_id = i.product_id
WHERE p.product_id IS NULL
UNION ALL
SELECT 'orphan: order -> campaign', COUNT(*)
FROM silver.erp_order AS o
LEFT JOIN silver.crm_campaign AS c ON c.campaign_id = o.campaign_id
WHERE o.campaign_id <> 'None' AND c.campaign_id IS NULL
UNION ALL
SELECT 'negative amount in orders', COUNT(*)
FROM silver.erp_order
WHERE subtotal_amount < 0 OR total_amount < 0 OR shipping_fee_total < 0
UNION ALL
SELECT 'negative qty/price in items', COUNT(*)
FROM silver.erp_order_items
WHERE quantity < 0 OR unit_price < 0 OR line_total < 0
UNION ALL
SELECT 'line_total <> quantity * unit_price_after_discount', COUNT(*)
FROM silver.erp_order_items
WHERE ABS(line_total - quantity * unit_price_after_discount) > 0.01
UNION ALL
SELECT 'line_total <> quantity * unit_price_after_discount - shipping_fee_item', COUNT(*)
FROM silver.erp_order_items
WHERE ABS(line_total - (quantity * unit_price_after_discount - ISNULL(shipping_fee_item, 0))) > 0.01
UNION ALL
SELECT 'delivery_end < delivery_start', COUNT(*)
FROM silver.erp_order_items
WHERE estimated_delivery_end < estimated_delivery_start
UNION ALL
SELECT 'registration_date in the future', COUNT(*)
FROM silver.crm_customer
WHERE registration_date > CAST(GETDATE() AS DATE)
UNION ALL
SELECT 'campaign end_date < start_date', COUNT(*)
FROM silver.crm_campaign
WHERE end_date < [start_date]
GO

-- 3. NULL count per column for every Silver table (replace the 4 repeated DECLARE blocks)
DECLARE @tbl SYSNAME, @sql NVARCHAR(MAX);
DECLARE tbl_cursor CURSOR FOR
    SELECT name FROM sys.tables WHERE schema_id = SCHEMA_ID('silver');
OPEN tbl_cursor;
FETCH NEXT FROM tbl_cursor INTO @tbl;
WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @sql = N'SELECT ''' + @tbl + N''' AS table_name, COUNT(*) AS total_rows, '
        + STRING_AGG(CAST(N'SUM(CASE WHEN ' + QUOTENAME(COLUMN_NAME)
                          + N' IS NULL THEN 1 ELSE 0 END) AS ' + QUOTENAME(COLUMN_NAME) AS NVARCHAR(MAX)), N', ')
        + N' FROM silver.' + QUOTENAME(@tbl)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'silver' AND TABLE_NAME = @tbl;

    EXEC sp_executesql @sql;
    FETCH NEXT FROM tbl_cursor INTO @tbl;
END
CLOSE tbl_cursor;
DEALLOCATE tbl_cursor;
GO
