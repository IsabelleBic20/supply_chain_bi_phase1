# Supply Chain BI & Data Quality — Data Stewardship Project

A practical **Supply Chain Business Intelligence and Data Stewardship project** designed to simulate real-world challenges involving data quality, data governance, analytical modeling, and BI reporting.

The project covers the data lifecycle from raw operational data profiling and quality assessment through root cause analysis, staging, dimensional modeling, metric engineering, and interactive Tableau dashboards.

---

## Tableau Dashboard

The interactive dashboard was developed in Tableau Public to monitor supply chain performance, delivery execution, business metrics, and data quality.

**[View the Supply Chain BI — Operations & Data Quality Dashboard](https://public.tableau.com/views/SupplyChainBI/SupplyChainBIOperationsDataQuality)**

### Dashboard topics

- Order volume and order value
- Order status and operational performance
- Delivery performance
- Data quality monitoring
- Transport cost analysis
- Carrier and service-level performance

---

## 1. Project Objective

Transform operational Supply Chain data containing intentional quality issues into a more reliable and governed analytical dataset suitable for BI and decision-making.

The project demonstrates how a Data Steward / BI professional can:

- Profile and assess raw data quality
- Identify data quality violations
- Investigate potential root causes
- Apply controlled transformations
- Preserve raw data immutability
- Implement data quality flags
- Build a dimensional data model
- Define reusable business metrics
- Deliver analytical dashboards
- Document data quality rules and governance decisions

---

## 2. Architecture

```text
┌──────────────────┐
│     RAW DATA     │
│  CSV Operational │
│      Data        │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────┐
│   DATA PROFILING & DQ    │
│  Completeness            │
│  Uniqueness              │
│  Validity                │
│  Referential Integrity   │
│  Consistency             │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│   ROOT CAUSE ANALYSIS    │
│  Evidence & hypotheses   │
│  Business validation     │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│      STAGING LAYER       │
│  Deduplication           │
│  Standardization         │
│  DQ flags                │
│  Data enrichment         │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│   DIMENSIONAL MODEL      │
│      Star Schema         │
│                          │
│  fct_orders              │
│  fct_deliveries          │
│  dim_customer            │
│  dim_product             │
│  dim_warehouse           │
│  dim_supplier            │
│  dim_carrier             │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│       BI / TABLEAU       │
│  Operational KPIs        │
│  Delivery Performance    │
│  Data Quality Monitoring │
└──────────────────────────┘
```

---

## 3. Technology Stack

| Technology          | Purpose                                            |
| ------------------- | -------------------------------------------------- |
| **DuckDB**          | Local analytical database and SQL processing       |
| **SQL**             | Profiling, transformation, validation and modeling |
| **Python / Pandas** | Data preparation and analysis support              |
| **Tableau Public**  | Interactive BI dashboards                          |
| **Git / GitHub**    | Version control and project documentation          |
| **Markdown**        | Technical documentation                            |

> DuckDB was used as a free local analytical engine. The architectural concepts demonstrated in this project are transferable to cloud data platforms such as Snowflake.

---

## 4. Raw Data Layer

The project uses synthetic operational Supply Chain data.

| Table        | Raw Records | Primary Key    | Grain                         |
| ------------ | ----------: | -------------- | ----------------------------- |
| `orders`     |     100,080 | `order_id`     | One row per order transaction |
| `deliveries` |     100,050 | `delivery_id`  | One row per delivery          |
| `customers`  |       5,000 | `customer_id`  | One row per customer          |
| `products`   |       1,000 | `product_id`   | One row per product           |
| `warehouses` |          12 | `warehouse_id` | One row per warehouse         |
| `suppliers`  |          80 | `supplier_id`  | One row per supplier          |
| `carriers`   |          15 | `carrier_id`   | One row per carrier           |

The raw layer is intentionally preserved and treated as **immutable**.

---

## 5. Data Quality Assessment

The raw data was profiled using SQL and DuckDB across multiple data quality dimensions.

### Data Quality Rules

| ID     | Dimension             | Rule                                             | Violations | Severity | Treatment                             |
| ------ | --------------------- | ------------------------------------------------ | ---------: | -------- | ------------------------------------- |
| DQ-001 | Uniqueness            | `orders.order_id` must be unique                 |         80 | Critical | Deduplicate in staging                |
| DQ-002 | Uniqueness            | `deliveries.delivery_id` must be unique          |         50 | Critical | Deduplicate in staging                |
| DQ-003 | Completeness          | `orders.customer_id` should be populated         |        120 | Medium   | Preserve and flag                     |
| DQ-004 | Referential Integrity | `customer_id` should exist in `customers`        |         50 | High     | Preserve and classify                 |
| DQ-005 | Validity              | `quantity > 0`                                   |         60 | High     | Flag for investigation                |
| DQ-006 | Consistency           | `order_value = quantity * unit_price`            |         60 | High     | Investigate root cause                |
| DQ-007 | Standardization       | Status must use controlled vocabulary            |        100 | Medium   | Normalize in staging                  |
| DQ-008 | Completeness          | `transport_cost` should be populated             |        100 | Medium   | Flag missing values                   |
| DQ-009 | Validity              | `actual_delivery_date >= order_date`             |         75 | High     | Flag temporal inconsistency           |
| DQ-010 | Cardinality           | Multiple deliveries per order require validation |         50 | Low      | Investigated as technical duplication |

---

## 6. Key Data Quality Findings

### Negative Quantities and Order Value Mismatch

60 records contain negative quantities.

An important observed pattern is that:

```text
ABS(quantity) × unit_price = order_value
```

This suggests a possible sign-related issue or an alternative representation of returns/adjustments.

**Data Steward decision:** the raw value is not silently overwritten. The anomaly is flagged and preserved for business validation.

---

### Missing and Orphan Customer References

The analysis identified:

* 120 orders with `customer_id IS NULL`
* 50 orders referencing customer IDs that do not exist in the customer dimension

These represent different data quality dimensions:

* **Missing value:** completeness issue
* **Non-existing reference:** referential integrity issue

The records are preserved to avoid distorting operational and financial metrics.

Potential business explanations should be validated with the source-system/business owners rather than assumed.

---

### Duplicate Delivery Records

50 duplicate `delivery_id` values were identified.

Further investigation showed that the apparent multiple deliveries were caused by duplicated delivery records rather than legitimate split shipments.

The duplicates were therefore removed during staging while keeping the raw layer unchanged.

---

### Status Standardization

The raw dataset contains variations such as:

```text
Delivered
delivered

In Transit
in_transit

Cancelled
Canceled
```

These values were standardized during staging to prevent fragmented filtering and inconsistent BI metrics.

---

## 7. Staging Layer

The staging layer applies controlled and reproducible transformations.

Examples include:

* Deduplication using window functions
* Controlled status standardization
* Referential integrity checks
* Data quality flags
* Temporal validation
* Order value consistency checks

The raw source data remains unchanged.

Example:

```sql
ROW_NUMBER() OVER (
    PARTITION BY order_id
    ORDER BY order_id
)
```

is used to identify duplicate order records during staging.

---

## 8. Dimensional Data Model

The analytical model follows a **Star Schema / Kimball-style dimensional modeling approach**.

### Fact tables

#### `fct_orders`

**Grain:** one row per order.

Contains:

* Order identifiers
* Customer/product/warehouse/supplier/carrier keys
* Order date
* Quantity
* Unit price
* Order value
* Order status
* Data quality flags

#### `fct_deliveries`

**Grain:** one row per delivery.

Contains:

* Delivery identifiers
* Order relationship
* Promised delivery date
* Actual delivery date
* Transport cost
* Delivery status
* Data quality flags

### Dimensions

* `dim_customer`
* `dim_product`
* `dim_warehouse`
* `dim_supplier`
* `dim_carrier`

Surrogate keys are used in the dimensional model while source-system identifiers are retained for traceability.

---

## 9. Business Metrics

The project includes reusable analytical metrics for operational reporting.

### Order metrics

* Total Orders
* Total Order Value
* Average Order Value
* Total Quantity
* Orders with Data Quality Issues

### Delivery metrics

* Total Deliveries
* Average Transport Cost
* Total Transport Cost
* Delivery Performance
* Delivery Variance
* On-Time / Early Delivery Rate

### Data Quality metrics

* Violation count
* Violation rate
* Severity
* Data quality issues by rule
* Orders affected by DQ issues

---

## 10. Tableau Dashboard

The Tableau dashboard brings together operational and data quality perspectives.

### Main KPIs

* **100,000** Total Orders
* **80,809,613** Total Order Value
* **808.1** Average Order Value
* **180** Orders with DQ Issues

### Visualizations

* Monthly Order Performance
* Orders by Status
* Delivery Performance
* Data Quality Issues by Rule
* Transport Cost Analysis
* Carrier / Service-Level Analysis

The dashboard is available on Tableau Public:

**[Open the interactive Tableau Dashboard](https://public.tableau.com/views/SupplyChainBI/SupplyChainBIOperationsDataQuality)**

---

## 11. Data Governance Principles

The project follows four main governance principles:

### 1. Raw Data Immutability

Raw data is never overwritten or deleted during transformation.

### 2. Reproducible Transformations

Data corrections and standardization are implemented through documented SQL transformations.

### 3. Traceability

Source identifiers are retained alongside analytical surrogate keys.

### 4. Explicit Data Quality Metadata

Potentially problematic records are identified using explicit DQ flags rather than silently modified.

---

## 12. Repository Structure

```text
supply_chain_bi/
├── data/
│   ├── raw/
│   │   ├── customers.csv
│   │   ├── products.csv
│   │   ├── warehouses.csv
│   │   ├── suppliers.csv
│   │   ├── carriers.csv
│   │   ├── orders.csv
│   │   └── deliveries.csv
│   └── processed/
│       ├── orders_bi.csv
│       ├── deliveries_bi.csv
│       └── dq_summary.csv
│
├── docs/
│   └── data_quality_matrix.md
│
├── sql/
│   ├── profiling.sql
│   ├── root_cause_analysis.sql
│   ├── staging.sql
│   └── data_model.sql
│
├── data_inventory.csv
└── README.md
```

---

## 13. How to Reproduce

### Run data profiling

```bash
duckdb < sql/profiling.sql
```

### Run root cause analysis

```bash
duckdb < sql/root_cause_analysis.sql
```

### Build the staging layer

```bash
duckdb supply_chain.duckdb < sql/staging.sql
```

### Build the dimensional model

```bash
duckdb supply_chain.duckdb < sql/data_model.sql
```

The resulting analytical datasets can then be exported to CSV and connected to Tableau Public.

---

## 14. Project Status

* [x] Raw data ingestion
* [x] Data profiling
* [x] Data quality assessment
* [x] Root cause analysis
* [x] Data quality matrix
* [x] Staging layer
* [x] Dimensional modeling
* [x] Business metric engineering
* [x] Tableau dashboard
* [x] Tableau Public publication
* [x] GitHub documentation

---

## 15. Portfolio Objective

This project demonstrates practical experience with:

* Data Quality Management
* Data Stewardship
* SQL
* Data Profiling
* Root Cause Analysis
* Data Governance
* Dimensional Modeling
* BI Metrics
* Tableau
* Analytical Data Preparation
* Documentation and Traceability

The project is based on synthetic data and is intended as a portfolio demonstration of analytical engineering and Data Stewardship practices.
