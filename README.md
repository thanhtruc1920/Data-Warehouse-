# Data_Warehouse_Shopee_ThaiLan
The project includes 4 data files containing order information from Thai Lan customers on the Shopee e-commerce platform.

## Datasets:
shopee_orders_thailan:

	|  order_id  | INT  | Primary Key
	
	| order_date | DATE | 
	
	| customer_id | VARCHAR(50) |
	
	|  year_month |   CHAR(7)   |
	|  subtotal_amount   | DECIMAL(20, 2) |

	| shipping_fee_total | DECIMAL(20, 2) |
	
	|  commission_total  | DECIMAL(20, 2) |
	
	| maintenance_total  | DECIMAL(20, 2) |
	
	| total_amount | DECIMAL(20, 2) |
	
	| campaign_id  |  VARCHAR(50)   |
  
shopee_order_items_thailan:

	| order_item_id | INT |
	
	|   order_id    | INT |
	
	| product_id | VARCHAR(50) |
	
	|  quantity  |  SMALLINT   |
	
	| unit_price | DECIMAL(20, 2) |
	
	| unit_price_after_discount | DECIMAL(20, 2) |
	
	| line_total | DECIMAL(20, 2) |
	
	|  discount_percent  | DECIMAL(20, 2) |
	
	| commission_amount  | DECIMAL(20, 2) |
	
	| maintenance_amount | DECIMAL(20, 2) |
	
	| shipping_fee_item  | DECIMAL(20, 2) |
	
	| estimated_delivery_start | DATE |
	
	|  estimated_delivery_end  | DATE |
	
	| item_status | NVARCHAR(50) |
	
	| is_campaign |   BIT   |
	
	| product_campaign_id | VARCHAR(50) |

shopee_products_thailan:

	| product_id | VARCHAR(50) |
	
	| seller_id  | VARCHAR(50) |
	
	|  category  | NVARCHAR(50) |
	
	| product_name | NVARCHAR(50) |
	
	| maintenance_rate | DECIMAL(20, 3) |
	
	| commission_rate  | DECIMAL(20, 2) |
	
	|   weight   |   DECIMAL(20, 2)   |
	
	| created_at |   DATE   |

shopee_customers_thailan:

	| customer_id | VARCHAR(50)  |
	
	| first_name  | NVARCHAR(50) |
	
	|  last_name  | NVARCHAR(50) |
	
	| gender | NVARCHAR(10) |
	
	|  dob   |   DATE   |

	| registration_date | DATE |
	
	| phone |   INT   |
	
	| email | NVARCHAR(100) |
	
	| province | NVARCHAR(50) |
	
	|   city   | NVARCHAR(50) |

