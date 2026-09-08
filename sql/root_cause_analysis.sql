-- =========================================================
-- ROOT CAUSE ANALYSIS
-- =========================================================

-- =========================================================
-- CASE A: Negative quantity
-- =========================================================

SELECT
    order_id,
    quantity,
    unit_price,
    order_value,
    quantity * unit_price AS calculated_value,
    ABS(quantity) * unit_price AS abs_calculated_value
FROM read_csv_auto('data/raw/orders.csv')
WHERE quantity <= 0
ORDER BY order_id;


-- =========================================================
-- CASE B: Customer quality
-- =========================================================

SELECT
    CASE
        WHEN o.customer_id IS NULL
            THEN 'NULL customer_id'
        WHEN c.customer_id IS NULL
            THEN 'Orphan customer_id'
        ELSE 'Valid'
    END AS customer_quality_status,
    COUNT(*) AS order_count
FROM read_csv_auto('data/raw/orders.csv') o
LEFT JOIN read_csv_auto('data/raw/customers.csv') c
    ON o.customer_id = c.customer_id
GROUP BY 1
ORDER BY 1;


-- =========================================================
-- CASE C: Multiple deliveries
-- =========================================================

WITH delivery_counts AS (
    SELECT
        order_id,
        COUNT(*) AS delivery_rows,
        COUNT(DISTINCT delivery_id) AS distinct_delivery_ids
    FROM read_csv_auto('data/raw/deliveries.csv')
    GROUP BY order_id
)

SELECT
    order_id,
    delivery_rows,
    distinct_delivery_ids,
    CASE
        WHEN delivery_rows > distinct_delivery_ids
            THEN 'Contains duplicate delivery_id'
        ELSE 'Distinct delivery_ids'
    END AS diagnosis
FROM delivery_counts
WHERE delivery_rows > 1
ORDER BY order_id;
