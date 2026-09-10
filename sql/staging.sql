-- =========================================================
-- PHASE 3: STAGING LAYER
-- =========================================================

-- =========================================================
-- STG ORDERS
-- =========================================================

CREATE OR REPLACE TABLE stg_orders AS

WITH raw_orders AS (
    SELECT *
    FROM read_csv_auto('data/raw/orders.csv')
),

deduplicated AS (
    SELECT *
    FROM raw_orders
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY order_id
        ORDER BY order_id
    ) = 1
)

SELECT
    order_id,

    customer_id,

    product_id,

    warehouse_id,

    supplier_id,

    carrier_id,

    order_date,

    quantity,

    unit_price,

    order_value,

    CASE
        WHEN LOWER(status) = 'delivered'
            THEN 'Delivered'

        WHEN LOWER(status) IN ('in_transit', 'in transit')
            THEN 'In Transit'

        WHEN LOWER(status) IN ('cancelled', 'canceled')
            THEN 'Cancelled'

        ELSE 'Unknown'
    END AS status,

    -- Data Quality flags

    quantity <= 0
        AS dq_flag_negative_quantity,

    customer_id IS NULL
        AS dq_flag_missing_customer,

    order_value != ROUND(quantity * unit_price, 2)
        AS dq_flag_order_value_mismatch,

    CASE
        WHEN customer_id IS NULL
            THEN 'Missing customer_id'

        WHEN customer_id NOT IN (
            SELECT customer_id
            FROM read_csv_auto('data/raw/customers.csv')
        )
            THEN 'Orphan customer_id'

        ELSE 'Valid'
    END AS customer_quality_status

FROM deduplicated;


-- =========================================================
-- STG DELIVERIES
-- =========================================================

CREATE OR REPLACE TABLE stg_deliveries AS

WITH raw_deliveries AS (
    SELECT *
    FROM read_csv_auto('data/raw/deliveries.csv')
),

deduplicated_deliveries AS (
    SELECT *
    FROM raw_deliveries
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY delivery_id
        ORDER BY delivery_id
    ) = 1
),

unique_orders AS (
    SELECT DISTINCT
        order_id,
        order_date
    FROM read_csv_auto('data/raw/orders.csv')
)

SELECT
    d.delivery_id,
    d.order_id,
    d.promised_delivery_date,
    d.actual_delivery_date,
    d.transport_cost,
    d.delivery_status,

    d.transport_cost IS NULL
        AS dq_flag_missing_transport_cost,

    d.actual_delivery_date < o.order_date
        AS dq_flag_invalid_delivery_date

FROM deduplicated_deliveries d

LEFT JOIN unique_orders o
    ON d.order_id = o.order_id;
