CREATE DATABASE olist_ecommerce;
USE olist_ecommerce;

CREATE TABLE customers (
	customer_id					VARCHAR(50) PRIMARY KEY,
	customer_unique_id			VARCHAR(50),
	customer_zip_code_prefix	VARCHAR(10),
	customer_city				VARCHAR(100),
	customer_state				VARCHAR(10)
);

CREATE TABLE orders (
	order_id						VARCHAR(50) PRIMARY KEY,
	customer_id						VARCHAR(50),
	order_status					VARCHAR (20),
	order_purchase_timestamp		DATETIME,
	order_approved_at				DATETIME,
	order_delivered_carrier_date	DATETIME,
	order_delivered_customer_date	DATETIME,
	order_estimated_delivery_date	DATETIME
);

CREATE TABLE order_items (
	order_id				VARCHAR(50),
	order_item_id			INT,
	product_id				VARCHAR(50),
	seller_id				VARCHAR(50),
	shipping_limit_date		DATETIME,
	price					DECIMAL(10,2),
	freight_value			DECIMAL(10,2)
);

CREATE TABLE order_payments (
	order_id				VARCHAR(50),
	payment_sequential		INT,
	payment_type			VARCHAR(50),
	payment_installments	INT,
	payment_value			DECIMAL(10,2)
);

CREATE TABLE products (
	product_id					VARCHAR(50) PRIMARY KEY,
	product_category_name		VARCHAR(100),
	product_name_lenght			INT,
	product_description_lenght	INT,
	product_photos_qty			INT,
	product_weight_g			DECIMAL(10,2),
	product_length_cm			DECIMAL(10,2),
	product_height_cm			DECIMAL(10,2),
	product_width_cm			DECIMAL(10,2),
);

CREATE TABLE sellers (
	seller_id				VARCHAR(50) PRIMARY KEY,
	seller_zip_code_prefix	VARCHAR(10),
	seller_city				VARCHAR(100),
	seller_state			VARCHAR(100)
);

CREATE TABLE product_category_name_translation (
	product_category_name			VARCHAR(100) PRIMARY KEY,
	product_category_name_english	VARCHAR(100)
);

CREATE TABLE geolocation (
	geolocation_zip_code_prefix	VARCHAR(10),
	geolocation_lat				DECIMAL(18,15),
	geolocation_lng				DECIMAL(18,15),
	geolocation_city			VARCHAR(100),
	geolocation_state			VARCHAR(100)
);