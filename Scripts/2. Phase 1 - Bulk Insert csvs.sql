BULK INSERT customers
FROM 'C:\Users\junus\Downloads\My Portfolio\SQL\Olist Ecommerce EDA\Raw data\olist_customers_dataset.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', TABLOCK);

BULK INSERT order_items
FROM 'C:\Users\junus\Downloads\My Portfolio\SQL\Olist Ecommerce EDA\Raw data\olist_order_items_dataset.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', TABLOCK);

BULK INSERT order_payments
FROM 'C:\Users\junus\Downloads\My Portfolio\SQL\Olist Ecommerce EDA\Raw data\olist_order_payments_dataset.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', TABLOCK);

BULK INSERT orders
FROM 'C:\Users\junus\Downloads\My Portfolio\SQL\Olist Ecommerce EDA\Raw data\olist_orders_dataset.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', TABLOCK);

BULK INSERT products
FROM 'C:\Users\junus\Downloads\My Portfolio\SQL\Olist Ecommerce EDA\Raw data\olist_products_dataset.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', TABLOCK);

BULK INSERT sellers
FROM 'C:\Users\junus\Downloads\My Portfolio\SQL\Olist Ecommerce EDA\Raw data\olist_sellers_dataset.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', TABLOCK);

BULK INSERT product_category_name_translation
FROM 'C:\Users\junus\Downloads\My Portfolio\SQL\Olist Ecommerce EDA\Raw data\product_category_name_translation.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', TABLOCK);

BULK INSERT geolocation
FROM 'C:\Users\junus\Downloads\My Portfolio\SQL\Olist Ecommerce EDA\Raw data\olist_geolocation_dataset.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a', TABLOCK);

-- order_reviews needs to be imported via the Import Flat File Wizard