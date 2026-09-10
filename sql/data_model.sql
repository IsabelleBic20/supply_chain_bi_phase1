-- =========================================================
-- PHASE 4: DATA MODEL
-- DIM CUSTOMER
-- =========================================================

CREATE OR REPLACE TABLE dim_customer AS

SELECT
    ROW_NUMBER() OVER (
        ORDER BY customer_id
    ) AS customer_key,

    customer_id,
    customer_name,
    segment
   

FROM read_csv_auto('data/raw/customers.csv');
-- =========================================================
-- DIM PRODUCT
-- =========================================================

CREATE OR REPLACE TABLE dim_product AS

SELECT
    ROW_NUMBER() OVER (
        ORDER BY product_id
    ) AS product_key,

    product_id,
    product_name,
    category

FROM read_csv_auto('data/raw/products.csv');

-- =========================================================
-- DIM WAREHOUSE
-- =========================================================

CREATE OR REPLACE TABLE dim_warehouse AS

SELECT
    ROW_NUMBER() OVER (
        ORDER BY warehouse_id
    ) AS warehouse_key,

    warehouse_id,
    warehouse_name,
    country,
    capacity

FROM read_csv_auto('data/raw/warehouses.csv');
-- =========================================================
-- DIM SUPPLIER
-- =========================================================

CREATE OR REPLACE TABLE dim_supplier AS

SELECT
    ROW_NUMBER() OVER (
        ORDER BY supplier_id
    ) AS supplier_key,

    supplier_id,
    supplier_name,
    country

FROM read_csv_auto('data/raw/suppliers.csv');
-- =========================================================
-- DIM CARRIER
-- =========================================================

CREATE OR REPLACE TABLE dim_carrier AS

SELECT
    ROW_NUMBER() OVER (
        ORDER BY carrier_id
    ) AS carrier_key,

    carrier_id,
    carrier_name,
    service_level

FROM read_csv_auto('data/raw/carriers.csv');
-- =========================================================
-- FACT ORDERS
-- Grain: 1 row per order
-- =========================================================

CREATE OR REPLACE TABLE fct_orders AS

SELECT
    ROW_NUMBER() OVER (
        ORDER BY o.order_id
    ) AS order_key,

    o.order_id,

    c.customer_key,
    p.product_key,
    w.warehouse_key,
    s.supplier_key,
    cr.carrier_key,

    o.order_date,
    o.quantity,
    o.unit_price,
    o.order_value,
    o.status,

    o.dq_flag_negative_quantity,
    o.dq_flag_missing_customer,
    o.dq_flag_order_value_mismatch,
    o.customer_quality_status

FROM stg_orders o

LEFT JOIN dim_customer c
    ON o.customer_id = c.customer_id

LEFT JOIN dim_product p
    ON o.product_id = p.product_id

LEFT JOIN dim_warehouse w
    ON o.warehouse_id = w.warehouse_id

LEFT JOIN dim_supplier s
    ON o.supplier_id = s.supplier_id

LEFT JOIN dim_carrier cr
    ON o.carrier_id = cr.carrier_id;
-- =========================================================
-- FACT DELIVERIES
-- Grain: 1 row per delivery
-- =========================================================

CREATE OR REPLACE TABLE fct_deliveries AS

SELECT
    ROW_NUMBER() OVER (
        ORDER BY d.delivery_id
    ) AS delivery_key,

    d.delivery_id,

    o.order_key,
    d.order_id,

    d.promised_delivery_date,
    d.actual_delivery_date,
    d.transport_cost,
    d.delivery_status,

    d.dq_flag_missing_transport_cost,
    d.dq_flag_invalid_delivery_date

FROM stg_deliveries d

LEFT JOIN fct_orders o
    ON d.order_id = o.order_id;
-- =========================================================
-- DATA QUALITY SUMMARY - ORDERS
-- =========================================================

CREATE OR REPLACE TABLE dq_orders_summary AS

SELECT
    'DQ-005' AS rule_id,
    'Negative quantity' AS rule_name,
    'Validity' AS dimension,
    SUM(CASE WHEN dq_flag_negative_quantity = TRUE THEN 1 ELSE 0 END) AS violation_count,
    COUNT(*) AS total_records,
    ROUND(
        100.0 * SUM(CASE WHEN dq_flag_negative_quantity = TRUE THEN 1 ELSE 0 END)
        / COUNT(*),
        4
    ) AS violation_rate_pct,
    'High' AS severity
FROM fct_orders

UNION ALL

SELECT
    'DQ-003' AS rule_id,
    'Missing customer' AS rule_name,
    'Completeness' AS dimension,
    SUM(CASE WHEN dq_flag_missing_customer = TRUE THEN 1 ELSE 0 END) AS violation_count,
    COUNT(*) AS total_records,
    ROUND(
        100.0 * SUM(CASE WHEN dq_flag_missing_customer = TRUE THEN 1 ELSE 0 END)
        / COUNT(*),
        4
    ) AS violation_rate_pct,
    'Medium' AS severity
FROM fct_orders

UNION ALL

SELECT
    'DQ-006' AS rule_id,
    'Order value mismatch' AS rule_name,
    'Consistency' AS dimension,
    SUM(CASE WHEN dq_flag_order_value_mismatch = TRUE THEN 1 ELSE 0 END) AS violation_count,
    COUNT(*) AS total_records,
    ROUND(
        100.0 * SUM(CASE WHEN dq_flag_order_value_mismatch = TRUE THEN 1 ELSE 0 END)
        / COUNT(*),
        4
    ) AS violation_rate_pct,
    'High' AS severity
FROM fct_orders;
-- =========================================================
-- DATA QUALITY SUMMARY - DELIVERIES
-- =========================================================

CREATE OR REPLACE TABLE dq_deliveries_summary AS

SELECT
    'DQ-008' AS rule_id,
    'Missing transport cost' AS rule_name,
    'Completeness' AS dimension,
    SUM(
        CASE
            WHEN dq_flag_missing_transport_cost = TRUE THEN 1
            ELSE 0
        END
    ) AS violation_count,
    COUNT(*) AS total_records,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN dq_flag_missing_transport_cost = TRUE THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        4
    ) AS violation_rate_pct,
    'Medium' AS severity
FROM fct_deliveries

UNION ALL

SELECT
    'DQ-009' AS rule_id,
    'Invalid delivery date' AS rule_name,
    'Validity' AS dimension,
    SUM(
        CASE
            WHEN dq_flag_invalid_delivery_date = TRUE THEN 1
            ELSE 0
        END
    ) AS violation_count,
    COUNT(*) AS total_records,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN dq_flag_invalid_delivery_date = TRUE THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        4
    ) AS violation_rate_pct,
    'High' AS severity
FROM fct_deliveries;
-- =========================================================
-- UNIFIED DATA QUALITY SUMMARY
-- =========================================================

CREATE OR REPLACE TABLE dq_summary AS

SELECT *
FROM dq_orders_summary

UNION ALL

SELECT *
FROM dq_deliveries_summary;
-- =========================================================
-- ORDER BUSINESS METRICS
-- =========================================================

CREATE OR REPLACE VIEW vw_order_metrics AS

SELECT
    COUNT(*) AS total_orders,

    SUM(quantity) AS total_quantity,

    ROUND(
        SUM(order_value),
        2
    ) AS total_order_value,

    ROUND(
        AVG(order_value),
        2
    ) AS average_order_value,

    SUM(
        CASE
            WHEN status = 'Delivered' THEN 1
            ELSE 0
        END
    ) AS delivered_orders,

    SUM(
        CASE
            WHEN status = 'In Transit' THEN 1
            ELSE 0
        END
    ) AS in_transit_orders,

    SUM(
        CASE
            WHEN status = 'Cancelled' THEN 1
            ELSE 0
        END
    ) AS cancelled_orders,

    SUM(
        CASE
            WHEN dq_flag_negative_quantity
              OR dq_flag_missing_customer
              OR dq_flag_order_value_mismatch
            THEN 1
            ELSE 0
        END
    ) AS orders_with_dq_issue

FROM fct_orders;
-- =========================================================
-- DELIVERY BUSINESS METRICS
-- =========================================================

CREATE OR REPLACE VIEW vw_delivery_metrics AS

SELECT
    COUNT(*) AS total_deliveries,

    ROUND(
        SUM(transport_cost),
        2
    ) AS total_transport_cost,

    ROUND(
        AVG(transport_cost),
        2
    ) AS average_transport_cost,

    SUM(
        CASE
            WHEN delivery_status = 'Delivered' THEN 1
            ELSE 0
        END
    ) AS delivered_deliveries,

    SUM(
        CASE
            WHEN delivery_status = 'In Transit' THEN 1
            ELSE 0
        END
    ) AS in_transit_deliveries,

    SUM(
        CASE
            WHEN dq_flag_missing_transport_cost THEN 1
            ELSE 0
        END
    ) AS missing_transport_cost,

    SUM(
        CASE
            WHEN dq_flag_invalid_delivery_date THEN 1
            ELSE 0
        END
    ) AS invalid_delivery_dates,

    ROUND(
        AVG(
            CASE
                WHEN actual_delivery_date IS NOT NULL
                THEN DATE_DIFF(
                    'day',
                    promised_delivery_date,
                    actual_delivery_date
                )
            END
        ),
        2
    ) AS average_delivery_variance_days,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN actual_delivery_date IS NOT NULL
                 AND actual_delivery_date <= promised_delivery_date
                THEN 1
                ELSE 0
            END
        )
        / NULLIF(
            SUM(
                CASE
                    WHEN actual_delivery_date IS NOT NULL
                    THEN 1
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS on_time_delivery_rate_pct

FROM fct_deliveries;

-- =========================================================
-- BI VIEW - ORDERS
-- Grain: 1 row per order
-- =========================================================

CREATE OR REPLACE VIEW vw_orders_bi AS

SELECT
    o.order_key,
    o.order_id,
    o.order_date,

    o.quantity,
    o.unit_price,
    o.order_value,
    o.status,

    c.customer_key,
    c.customer_id,
    c.customer_name,
    c.segment AS customer_segment,

    p.product_key,
    p.product_id,
    p.product_name,
    p.category AS product_category,

    w.warehouse_key,
    w.warehouse_id,
    w.warehouse_name,
    w.country AS warehouse_country,
    w.capacity AS warehouse_capacity,

    s.supplier_key,
    s.supplier_id,
    s.supplier_name,
    s.country AS supplier_country,

    cr.carrier_key,
    cr.carrier_id,
    cr.carrier_name,
    cr.service_level AS carrier_service_level,

    o.dq_flag_negative_quantity,
    o.dq_flag_missing_customer,
    o.dq_flag_order_value_mismatch,
    o.customer_quality_status

FROM fct_orders o

LEFT JOIN dim_customer c
    ON o.customer_key = c.customer_key

LEFT JOIN dim_product p
    ON o.product_key = p.product_key

LEFT JOIN dim_warehouse w
    ON o.warehouse_key = w.warehouse_key

LEFT JOIN dim_supplier s
    ON o.supplier_key = s.supplier_key

LEFT JOIN dim_carrier cr
    ON o.carrier_key = cr.carrier_key;
