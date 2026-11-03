# Data_Warehouse_Shopee_ThaiLan
The project includes 4 data files containing order information from Thai Lan customers on the Shopee e-commerce platform.

## Datasets:
shopee_orders_thailan:
| Column | Data Type | Description | Key |
|--------|-----------|-------------|-----|
|  order_id  | INT  | PK | A unique 6 to 7 digit transaction identifier |
| order_date | DATE | The transaction timestamp |
| customer_id | VARCHAR(50) | FK -> shopee_customers_thailan.customer_id |
|  year_month |   CHAR(7)   | Order time |
|  subtotal_amount   | DECIMAL(20, 2) | The total Gross Merchandise Value (GMV) per order before overheads |
| shipping_fee_total | DECIMAL(20, 2) | Aggregated delivery costs |
|  commission_total  | DECIMAL(20, 2) | Total marketplace fees collected |
| maintenance_total  | DECIMAL(20, 2) | Operational or service overheads applied to the order |
| total_amount | DECIMAL(20, 2) | The final settlement value paid by the customer ($Subtotal + Shipping$) |
<br>

shopee_order_items_thailan:
| Column | Data Type | Key |
|--------|-----------|-----|
| order_item_id | INT | Unique identifier for each specific line item in an order | PK |
|   order_id    | INT | FK -> shopee_orders_thailan.order_id |
| product_id | VARCHAR(50) | FK -> shopee_products_thailan.product_id |
|  quantity  |  SMALLINT   | The number of units purchased for a specific product within the order |
| unit_price | DECIMAL(20, 2) | The original retail price of a single unit before any discounts are applied |
| unit_price_after_discount | DECIMAL(20, 2) | The final price per unit paid by the customer after applying campaign or shop discounts |
| line_total | DECIMAL(20, 2) | The total value for the specific line item ($Quantity*Unit\_Price\_After\_Discount$) |
|  discount_percent  | DECIMAL(20, 2) | The percentage of discount applied to the original unit price |
| commission_amount  | DECIMAL(20, 2) | The fee charged by the platform to the seller for the transaction |
| maintenance_amount | DECIMAL(20, 2) | Operational or platform fees associated with the product handling |
| shipping_fee_item  | DECIMAL(20, 2) | The delivery cost allocated to this specific item |
| estimated_delivery_start | DATE | The earliest predicted date for the customer to receive the item |
|  estimated_delivery_end  | DATE | The latest predicted date for delivery |
| item_status | NVARCHAR(50) | The current lifecycle stage of the item (e.g., Completed, Cancelled, Returned) |
<br>

shopee_products_thailan:
| Column | Data Type | Key |
|--------|-----------|-----|
| product_id | VARCHAR(50) | Unique Primary Key for the catalog | PK |
|  category  | NVARCHAR(50) | High-level product classification (e.g., Beauty, Fashion, Electronics) |
| product_name | NVARCHAR(50) | Product name |
| maintenance_rate | DECIMAL(20, 3) | Fixed operational fee percentage per product |
| commission_rate  | DECIMAL(20, 2) | The marketplace fee percentage charged to the seller |
|   weight   |   DECIMAL(20, 2)   | Product weight in kilograms |
| created_at |   DATE   | The registration date of the product in the system |
<br>

shopee_customers_thailan:
| Column | Data Type | Key |
|--------|-----------|-----|
| customer_id | VARCHAR(50)  | Unique identifier for each user | PK |
| first_name  | NVARCHAR(50) | The given name of the customer |
|  last_name  | NVARCHAR(50) | The family name of the customer |
| gender | NVARCHAR(10) | Biological sex of the user |
|  dob   |   DATE   | Date of Birth |
| registration_date | DATE | The date the user joined the platform |
| phone |   INT   | Contact phone number for the user |
| email | NVARCHAR(100) | Email address |
| province | NVARCHAR(50) | The primary administrative division in Thailand where the customer is located |
|   city   | NVARCHAR(50) | The specific city or district of the customer |
<br>

## Tools:
   • SQL 
   • Draw.io
<br>

## Objective:
🔹 Built SQL-based ETL pipelines to transform raw data into structured datasets and manage data flow:

   		– Bronze layer (raw data): Extract data (CRM, CSV files, ...). 
	
		– Silver layer (data cleaning): Transform data (process data). 
	
   		– Gold layer (Star Schema): Load data (create Primary Key, Foreign Key). 
	
🔹 Designed data warehouse and star schema models using draw.io.

