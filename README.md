# Olist-E-Commerce-Exploratory-Data-Analysis
**Tool:** Microsoft SQL Server 2025  
**Dataset:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle)  
**Status:** 🔄 In progress

---

## 📁 Project Structure

```
olist-eda/
│
├── raw_data/                  # Original CSV files (not tracked in git)
├── scripts/
│   ├── 01_create_tables.sql   # Table definitions
│   ├── 02_bulk_insert.sql     # Data import scripts
│   └── 03_validation.sql      # Row count and integrity checks
└── README.md
```

---

## 📊 Dataset Overview

The Olist dataset contains anonymised transactional data from a Brazilian e-commerce marketplace between **2016 and 2018**. It consists of **9 relational tables** covering orders, customers, sellers, products, payments, reviews, and geolocation.

| Table | Description | Rows |
|---|---|---|
| `orders` | One row per order with status and timestamps | ~99,441 |
| `customers` | Customer location and unique IDs | ~99,441 |
| `order_items` | Line items per order (product, seller, price) | ~112,650 |
| `order_payments` | Payment method and value per order | ~103,886 |
| `order_reviews` | Customer review scores and comments | ~100,000 |
| `products` | Product attributes and category | ~32,951 |
| `sellers` | Seller location | ~3,095 |
| `geolocation` | Zip code to lat/lng mapping | ~1,000,163 |
| `product_category_name_translation` | Portuguese to English category names | ~71 |

---

## 🗂️ Schema Diagram

```
customers ──────────── orders ──────────── order_items ──── products
                          │                     │               │
                          │                     └────────── sellers
                          │
                    order_payments
                    order_reviews
```

---

## ⚙️ Phase 1 — Setup & Data Import

### Steps taken

1. Downloaded 9 CSV files from Kaggle
2. Created `olist_ecommerce` database in SSMS
3. Created all 9 tables with appropriate data types
4. Imported CSVs using `BULK INSERT`

### Data import notes

- **Line ending issue:** Kaggle CSVs use Unix-style line endings (`\n`). Used `ROWTERMINATOR = '0x0a'` in `BULK INSERT` to handle this correctly.
- **Truncation on state columns:** The `seller_state`, `customer_state`, and `geolocation_state` columns threw truncation errors when typed as `CHAR(2)` due to trailing `\r` carriage return characters on the last column of each row. Resolved by importing as `VARCHAR(100)`.

### Validation

All 9 tables passed row count validation after import:

```sql
SELECT 'customers'  AS tbl, COUNT(*) AS rows FROM customers  UNION ALL
SELECT 'orders',           COUNT(*)           FROM orders     UNION ALL
SELECT 'order_items',      COUNT(*)           FROM order_items UNION ALL
SELECT 'order_payments',   COUNT(*)           FROM order_payments UNION ALL
SELECT 'order_reviews',    COUNT(*)           FROM order_reviews UNION ALL
SELECT 'products',         COUNT(*)           FROM products    UNION ALL
SELECT 'sellers',          COUNT(*)           FROM sellers     UNION ALL
SELECT 'geolocation',      COUNT(*)           FROM geolocation UNION ALL
SELECT 'product_category_name_translation', COUNT(*) FROM product_category_name_translation;
```

---

## 🔜 Next Steps

- [ ] Phase 2 — Schema exploration & relationship validation
- [ ] Phase 3 — Data cleaning & preparation
- [ ] Phase 4 — Core analysis (revenue, customers, delivery, sellers)
- [ ] Phase 5 — Advanced SQL (window functions, CTEs, cohort analysis)
- [ ] Phase 6 — Key findings write-up
