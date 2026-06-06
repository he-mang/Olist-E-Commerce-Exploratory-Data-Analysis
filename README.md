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

## 🔍 Phase 2 — Schema Exploration

### Referential integrity

All foreign key relationships were validated using `LEFT JOIN` checks. Every record joins cleanly with no orphaned rows.

| Check | Result |
|---|---|
| Orders without a matching customer | 0 |
| Order items without a matching order | 0 |
| Order items without a matching product | 0 |
| Order items without a matching seller | 0 |

### Nulls in critical columns

**orders table**

| Column | Null count | Notes |
|---|---|---|
| `order_delivered_customer_date` | 2,965 | Expected — aligns with non-delivered order statuses (shipped, cancelled, etc.) |
| `order_approved_at` | 160 | Small — likely cancelled orders never approved. Safe to exclude from time-based analysis |
| `order_estimated_delivery_date` | 0 | Clean — all orders had an estimate |

**order_reviews table**

| Column | Null count | Notes |
|---|---|---|
| `review_score` | 0 | Fully populated — reliable for analysis |
| `review_comment_message` | 58,256 | Expected — review comments are optional. ~58% of customers left no written comment |

### Date range

The dataset spans **September 2016 to October 2018** (~2 years).

> ⚠️ Note: 2016 only contains 4 months of data (Sep–Dec). Year-over-year comparisons should either exclude 2016 or be clearly caveated.

### Order status breakdown

| Status | Count |
|---|---|
| delivered | 96,478 |
| shipped | 1,107 |
| canceled | 625 |
| unavailable | 609 |
| invoiced | 314 |
| processing | 301 |
| created | 5 |
| approved | 2 |

97% of orders have been delivered. Delivery performance analysis will filter to `WHERE order_status = 'delivered'` to avoid skewing averages with incomplete orders.

### Review score distribution

| Score | Count |
|---|---|
| ⭐ 1 | 11,424 |
| ⭐⭐ 2 | 3,151 |
| ⭐⭐⭐ 3 | 8,179 |
| ⭐⭐⭐⭐ 4 | 19,142 |
| ⭐⭐⭐⭐⭐ 5 | 57,328 |

Scores are positively skewed — the majority of customers are satisfied. The 1-star cluster (~11k) is worth investigating in Phase 4, likely correlated with late deliveries.

### Price range (order_items)

| Metric | Value (R$) |
|---|---|
| Min price | 0.85 |
| Max price | 6,735.00 |
| Avg price | 120.65 |

The max price of R$6,735 is a significant outlier. Revenue analysis will flag extreme values to assess their impact on averages.

### Product category translation coverage

| Check | Count |
|---|---|
| Products with an English category name | 32,328 |
| Products missing an English category name | 623 |

623 products (~2%) have no English translation. Category analysis will use `COALESCE` to fall back to the Portuguese name rather than exclude these products:

```sql
COALESCE(t.product_category_name_english, p.product_category_name) AS category
```

---

## 🔜 Next Steps

- [x] Phase 2 — Schema exploration & relationship validation
- [ ] Phase 3 — Data cleaning & preparation
- [ ] Phase 4 — Core analysis (revenue, customers, delivery, sellers)
- [ ] Phase 5 — Advanced SQL (window functions, CTEs, cohort analysis)
- [ ] Phase 6 — Key findings write-up
