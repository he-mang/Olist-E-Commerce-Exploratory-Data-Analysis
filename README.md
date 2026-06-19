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

## 🧹 Phase 3 — Data Cleaning & Preparation

The goal of this phase was to produce clean, analysis-ready views that Phase 4 queries can build on without repeating the same filtering and joining logic every time.

### Findings

**Price outliers**

3 order items were found with a price below R$1.00 (0.003% of all items). These are negligible and considered legitimate low-value transactions — no rows removed.

**Duplicate order IDs**

No duplicate `order_id` values found in the `orders` table. Revenue and delivery aggregations are safe from double-counting.

**Duplicate review IDs — data quality issue identified**

764 `review_id` values appeared twice and 25 appeared three times in `order_reviews`. Investigation revealed that the same `review_id` was linked to multiple different `order_id`s, indicating a data quality issue in Olist's source system rather than an import error.

| Metric | Count |
|---|---|
| Total rows in `order_reviews` | 99,224 |
| Duplicate rows removed | 814 |
| Rows in deduplicated view | 98,410 |

All review analysis in Phase 4 uses `vw_reviews_deduped` to avoid inflated scores.

### Views created

Three views were created as the clean foundation for Phase 4 analysis:

**`vw_delivered_orders`**
Filters `orders` to only fully delivered orders with no null timestamps. Used as the base for all delivery performance and revenue analysis.

```sql
CREATE VIEW vw_delivered_orders AS
SELECT *
FROM orders
WHERE order_status = 'delivered'
AND order_delivered_customer_date IS NOT NULL
AND order_approved_at IS NOT NULL;
```

**`vw_products_translated`**
Joins `products` to the category translation table with `COALESCE` fallback for the 623 products without an English translation.

```sql
CREATE VIEW vw_products_translated AS
SELECT
    p.product_id,
    p.product_category_name,
    COALESCE(t.product_category_name_english, p.product_category_name) AS category_english,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM products p
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name;
```

**`vw_reviews_deduped`**
Deduplicates `order_reviews` by keeping one row per `review_id` (most recent where dates differ) using `ROW_NUMBER()`.

```sql
CREATE VIEW vw_reviews_deduped AS
SELECT *
FROM (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY review_id
            ORDER BY review_creation_date DESC
        ) AS rn
    FROM order_reviews
) AS ranked
WHERE rn = 1;
```

---

## 📊 Phase 4 — Core Analysis

All queries in this phase use the three cleaned views created in Phase 3 as base tables: `vw_delivered_orders`, `vw_products_translated`, and `vw_reviews_deduped`.

---

### Theme 1 — Sales & Revenue

**Query 1 — Monthly revenue trend**

| Metric | Finding |
|---|---|
| Dataset period | September 2016 – October 2018 |
| Peak month | November 2017 — R$1,153,229 across 7,288 orders (Black Friday) |
| 2017 growth | Revenue grew ~10x from R$127k (Jan) to R$1.15M (Nov) |
| 2018 trend | Revenue stabilised between R$966k – R$1.13M per month |
| Avg order value | Consistently between R$128 – R$166 throughout the entire period |

> ⚠️ 2016 data is incomplete (only Sep, Oct, Dec present with minimal orders) and is excluded from trend comparisons.

**Query 2 — Top 10 product categories by revenue**

| Category | Total Orders | Total Revenue | Avg Item Price |
|---|---|---|---|
| health_beauty | 8,647 | R$1,412,089 | R$149.19 |
| watches_gifts | 5,493 | R$1,264,017 | R$215.81 |
| bed_bath_table | 9,271 | R$1,225,052 | R$111.86 |
| sports_leisure | 7,527 | R$1,117,968 | R$132.65 |
| computers_accessories | 6,529 | R$1,032,604 | R$135.10 |
| furniture_decor | 6,304 | R$880,029 | R$107.89 |
| housewares | 5,743 | R$758,392 | R$111.61 |
| cool_stuff | 3,556 | R$691,372 | R$186.10 |
| auto | 3,809 | R$669,320 | R$161.71 |
| garden_tools | 3,447 | R$566,991 | R$132.88 |

Key observations:
- **Health & beauty** leads in total revenue and is the second highest volume category
- **Watches & gifts** has the highest average item price at R$215.81 — high ticket, lower volume
- **Bed, bath & table** has the highest order volume but ranks 3rd in revenue due to lower avg price

**Query 3 — Average order value by state (top 10)**

| State | Total Orders | Avg Order Value | Total Revenue |
|---|---|---|---|
| SP | 40,489 | R$142.45 | R$5,767,846 |
| RJ | 12,348 | R$166.44 | R$2,055,179 |
| MG | 11,351 | R$160.21 | R$1,818,600 |
| RS | 5,342 | R$161.12 | R$860,725 |
| PR | 4,923 | R$158.79 | R$781,709 |
| SC | 3,546 | R$167.83 | R$595,128 |
| BA | 3,256 | R$181.55 | R$591,138 |
| DF | 2,080 | R$166.41 | R$346,123 |
| GO | 1,957 | R$170.78 | R$334,212 |
| ES | 1,995 | R$159.23 | R$317,658 |

Key observations:
- **São Paulo dominates total revenue** at R$5.77M — more than 2.8x the next state (RJ)
- **SP has the lowest AOV** in the top 10 at R$142.45 — high volume drives revenue, not high spend per order
- **Bahia has the highest AOV** at R$181.55 despite ranking 7th in total orders

---

### Theme 2 — Customer Behaviour

**Query 4 — Repeat vs one-time buyers**

| Segment | Total Customers | % of Customers |
|---|---|---|
| One-time buyer | 90,537 | 97% |
| Bought twice | 2,572 | 2% |
| Bought three or more times | 228 | <1% |

> This is the most striking finding in the project. **97% of customers never returned for a second purchase**, indicating a significant retention problem. The business is almost entirely dependent on new customer acquisition.

**Query 5 — Top 10 states by customer count**

| State | Total Customers | % of Customers |
|---|---|---|
| SP | 40,302 | 41% |
| RJ | 12,384 | 12% |
| MG | 11,259 | 11% |
| RS | 5,277 | 5% |
| PR | 4,882 | 5% |
| SC | 3,534 | 3% |
| BA | 3,277 | 3% |
| DF | 2,075 | 2% |
| ES | 1,964 | 2% |
| GO | 1,952 | 2% |

Key observations:
- **SP alone accounts for 41% of all customers**
- **Top 3 states (SP, RJ, MG) account for 64% of the entire customer base** — heavily concentrated in Brazil's southeast

**Query 6 — Order frequency distribution**

| Orders Placed | Total Customers |
|---|---|
| 1 | 90,537 |
| 2 | 2,572 |
| 3 | 181 |
| 4 | 28 |
| 5 | 9 |
| 6 | 5 |
| 7 | 3 |
| 9 | 1 |
| 15 | 1 |

> The drop-off after the first order is dramatic. Only 1 customer placed 15 orders — the most loyal customer in the entire dataset.

---

### Theme 3 — Delivery Performance

**Query 7 — Overall delivery time**

| Metric | Days |
|---|---|
| Average | 12 |
| Median | 10 |
| Minimum | 0 |
| Maximum | 210 |

> The median (10) being lower than the mean (12) confirms a small number of extreme late deliveries are pulling the average up. The 0-day minimum and 210-day maximum are both worth investigating as potential data quality issues.

**Query 8 — Slowest states by average delivery time**

| State | Total Orders | Avg Delivery Days | Avg Days Before Estimate |
|---|---|---|---|
| RR | 41 | 29 | 17 |
| AP | 67 | 27 | 19 |
| AM | 145 | 26 | 19 |
| AL | 397 | 24 | 8 |
| PA | 946 | 23 | 14 |
| SE | 335 | 21 | 10 |
| CE | 1,278 | 21 | 10 |
| MA | 716 | 21 | 9 |
| AC | 80 | 21 | 20 |
| PB | 517 | 20 | 13 |

Key observations:
- **All 10 slowest states are in Brazil's north and northeast** — geography and distance from São Paulo distribution hubs is the primary driver
- **Roraima (RR) averages 29 days** — more than double the national average of 12 days
- **Positive `avg_days_before_estimate` across all states** indicates Olist sets conservative delivery estimates, arriving earlier than promised on average

**Query 9 — Late delivery rate by state (top 10 worst)**

| State | Total Orders | Late Orders | Late Delivery % |
|---|---|---|---|
| AL | 397 | 95 | 23% |
| MA | 716 | 141 | 19% |
| CE | 1,278 | 196 | 15% |
| SE | 335 | 51 | 15% |
| PI | 476 | 76 | 15% |
| BA | 3,256 | 457 | 14% |
| RJ | 12,348 | 1,664 | 13% |
| PA | 946 | 117 | 12% |
| ES | 1,995 | 244 | 12% |
| TO | 274 | 35 | 12% |

Key observations:
- **Alagoas (AL) has the worst late delivery rate at 23%** — nearly 1 in 4 orders arrives late
- **The northeast dominates the worst performers** — AL, MA, CE, SE, PI, BA all appear in the top 10
- **RJ is the biggest operational problem in absolute terms** — 1,664 late orders despite a 13% rate, due to its high order volume

**Query 10 — Late deliveries vs review scores**

| Delivery Status | Total Reviews | Avg Review Score |
|---|---|---|
| On Time | 33,241 | 4.30 |
| Late | 2,905 | 2.62 |

> **Late deliveries are associated with a 1.68 point drop in average review score.** This directly connects operational delivery performance to customer satisfaction and makes a compelling business case: improving delivery reliability in the northeast would likely have a measurable positive impact on platform-wide review scores.

---

### Theme 4 — Seller Performance

**Query 11 — Top 10 sellers by revenue**

| Seller ID | Total Orders | Total Revenue | Avg Order Value |
|---|---|---|---|
| 4869f7a5... | 1,124 | R$247,007 | R$215.16 |
| 7c67e144... | 973 | R$237,807 | R$175.50 |
| 4a3ca931... | 1,772 | R$231,220 | R$118.64 |
| 53243585... | 348 | R$230,797 | R$576.99 |
| fa1c13f2... | 578 | R$200,834 | R$346.86 |
| da8622b1... | 1,311 | R$184,707 | R$119.32 |
| 7e93a43e... | 319 | R$171,974 | R$534.08 |
| 1025f0e2... | 910 | R$171,925 | R$121.07 |
| 7a67c85e... | 1,142 | R$159,969 | R$138.86 |
| 955fee92... | 1,261 | R$156,606 | R$106.39 |

Key observations:
- **Two distinct seller profiles emerge** — high volume/moderate AOV sellers vs low volume/high AOV sellers
- **Seller `53243585`** generated R$230,797 from just 348 orders at R$576.99 AOV — almost certainly a high-ticket category (electronics, furniture)
- **Seller `7e93a43e`** similarly: R$171,974 from 319 orders at R$534.08 AOV

**Query 12 — Sellers with highest late delivery rate (min. 50 orders)**

| Seller ID | Total Orders | Late Orders | Late Delivery % |
|---|---|---|---|
| 2a261b5b... | 51 | 18 | 35% |
| 54965bbe... | 73 | 26 | 35% |
| 6039e272... | 63 | 19 | 30% |
| bbad7e51... | 68 | 19 | 27% |
| a49928bc... | 96 | 26 | 27% |
| beadbee3... | 64 | 16 | 25% |
| cac4c8e7... | 74 | 19 | 25% |
| ea566164... | 50 | 12 | 24% |
| 06a2c3af... | 389 | 95 | 24% |
| 88460e8e... | 246 | 59 | 23% |

Key observations:
- **Two sellers share the worst late delivery rate at 35%** — more than 1 in 3 of their orders arrives late
- **Seller `06a2c3af`** is the biggest operational risk — 389 orders with a 24% late rate means 95 customers received late deliveries from this seller alone
- Only sellers with 50+ orders were included to ensure statistically meaningful rates

**Query 13 — Freight cost vs review score**

| Freight Bucket | Total Reviews | Avg Review Score |
|---|---|---|
| Under R$10 | 5,820 | 4.21 |
| R$10 – R$24.99 | 28,343 | 4.10 |
| R$100+ | 255 | 4.00 |
| R$50 – R$99.99 | 1,417 | 3.98 |
| R$25 – R$49.99 | 5,347 | 3.98 |

Key observations:
- **Lower freight cost correlates with higher satisfaction** — customers paying under R$10 give the highest average score of 4.21
- **Scores decline as freight rises**, with R$25–R$99.99 scoring ~3.98
- **R$100+ scores slightly higher (4.00) than R$25–R$99.99** — customers paying premium freight for high-value or bulky items may have different expectations and higher overall satisfaction with their purchase

---

## 🔜 Next Steps

- [x] Phase 2 — Schema exploration & relationship validation
- [x] Phase 3 — Data cleaning & preparation
- [x] Phase 4 — Core analysis (revenue, customers, delivery, sellers)
- [ ] Phase 5 — Advanced SQL (window functions, CTEs, cohort analysis)
- [ ] Phase 6 — Key findings write-up

---
