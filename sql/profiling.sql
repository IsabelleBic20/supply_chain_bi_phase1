-- SUPPLY CHAIN BI PROJECT
-- PHASE 2 - DATA PROFILING & DATA QUALITY
-- DuckDB | Raw data is not modified

-- 1. QUANTITY OF RECORDS
SELECT 'orders' AS table_name, COUNT(*) AS total_rows FROM read_csv_auto('data/raw/orders.csv');
SELECT 'customers' AS table_name, COUNT(*) AS total_rows FROM read_csv_auto('data/raw/customers.csv');
SELECT 'products' AS table_name, COUNT(*) AS total_rows FROM read_csv_auto('data/raw/products.csv');
SELECT 'warehouses' AS table_name, COUNT(*) AS total_rows FROM read_csv_auto('data/raw/warehouses.csv');
SELECT 'suppliers' AS table_name, COUNT(*) AS total_rows FROM read_csv_auto('data/raw/suppliers.csv');
SELECT 'carriers' AS table_name, COUNT(*) AS total_rows FROM read_csv_auto('data/raw/carriers.csv');
SELECT 'deliveries' AS table_name, COUNT(*) AS total_rows FROM read_csv_auto('data/raw/deliveries.csv');


-- 2. PRIMARY KEY - NULL CHECKS
SELECT COUNT(*) AS total_rows, COUNT(order_id) AS non_null_ids,
       COUNT(*) - COUNT(order_id) AS null_ids
FROM read_csv_auto('data/raw/orders.csv');

SELECT COUNT(*) AS total_rows, COUNT(customer_id) AS non_null_ids,
       COUNT(*) - COUNT(customer_id) AS null_ids
FROM read_csv_auto('data/raw/customers.csv');

SELECT COUNT(*) AS total_rows, COUNT(product_id) AS non_null_ids,
       COUNT(*) - COUNT(product_id) AS null_ids
FROM read_csv_auto('data/raw/products.csv');

SELECT COUNT(*) AS total_rows, COUNT(warehouse_id) AS non_null_ids,
       COUNT(*) - COUNT(warehouse_id) AS null_ids
FROM read_csv_auto('data/raw/warehouses.csv');

SELECT COUNT(*) AS total_rows, COUNT(supplier_id) AS non_null_ids,
       COUNT(*) - COUNT(supplier_id) AS null_ids
FROM read_csv_auto('data/raw/suppliers.csv');

SELECT COUNT(*) AS total_rows, COUNT(carrier_id) AS non_null_ids,
       COUNT(*) - COUNT(carrier_id) AS null_ids
FROM read_csv_auto('data/raw/carriers.csv');

SELECT COUNT(*) AS total_rows, COUNT(delivery_id) AS non_null_ids,
       COUNT(*) - COUNT(delivery_id) AS null_ids
FROM read_csv_auto('data/raw/deliveries.csv');


-- 3. PRIMARY KEY - DUPLICATE CHECKS
SELECT order_id, COUNT(*) AS occurrences
FROM read_csv_auto('data/raw/orders.csv')
GROUP BY order_id HAVING COUNT(*) > 1 ORDER BY occurrences DESC;

SELECT customer_id, COUNT(*) AS occurrences
FROM read_csv_auto('data/raw/customers.csv')
GROUP BY customer_id HAVING COUNT(*) > 1 ORDER BY occurrences DESC;

SELECT product_id, COUNT(*) AS occurrences
FROM read_csv_auto('data/raw/products.csv')
GROUP BY product_id HAVING COUNT(*) > 1 ORDER BY occurrences DESC;

SELECT warehouse_id, COUNT(*) AS occurrences
FROM read_csv_auto('data/raw/warehouses.csv')
GROUP BY warehouse_id HAVING COUNT(*) > 1 ORDER BY occurrences DESC;

SELECT supplier_id, COUNT(*) AS occurrences
FROM read_csv_auto('data/raw/suppliers.csv')
GROUP BY supplier_id HAVING COUNT(*) > 1 ORDER BY occurrences DESC;

SELECT carrier_id, COUNT(*) AS occurrences
FROM read_csv_auto('data/raw/carriers.csv')
GROUP BY carrier_id HAVING COUNT(*) > 1 ORDER BY occurrences DESC;

SELECT delivery_id, COUNT(*) AS occurrences
FROM read_csv_auto('data/raw/deliveries.csv')
GROUP BY delivery_id HAVING COUNT(*) > 1 ORDER BY occurrences DESC;


-- 4. REFERENTIAL INTEGRITY

-- Orders -> Customers
SELECT COUNT(*) AS total_orders,
       COUNT(c.customer_id) AS matched_customers,
       COUNT(*) - COUNT(c.customer_id) AS unmatched_customers
FROM read_csv_auto('data/raw/orders.csv') AS o
LEFT JOIN read_csv_auto('data/raw/customers.csv') AS c
ON o.customer_id = c.customer_id;

SELECT o.order_id, o.customer_id
FROM read_csv_auto('data/raw/orders.csv') AS o
LEFT JOIN read_csv_auto('data/raw/customers.csv') AS c
ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Orders -> Products
SELECT COUNT(*) AS total_orders,
       COUNT(p.product_id) AS matched_products,
       COUNT(*) - COUNT(p.product_id) AS unmatched_products
FROM read_csv_auto('data/raw/orders.csv') AS o
LEFT JOIN read_csv_auto('data/raw/products.csv') AS p
ON o.product_id = p.product_id;

-- Orders -> Warehouses
SELECT COUNT(*) AS total_orders,
       COUNT(w.warehouse_id) AS matched_warehouses,
       COUNT(*) - COUNT(w.warehouse_id) AS unmatched_warehouses
FROM read_csv_auto('data/raw/orders.csv') AS o
LEFT JOIN read_csv_auto('data/raw/warehouses.csv') AS w
ON o.warehouse_id = w.warehouse_id;

-- Orders -> Suppliers
SELECT COUNT(*) AS total_orders,
       COUNT(s.supplier_id) AS matched_suppliers,
       COUNT(*) - COUNT(s.supplier_id) AS unmatched_suppliers
FROM read_csv_auto('data/raw/orders.csv') AS o
LEFT JOIN read_csv_auto('data/raw/suppliers.csv') AS s
ON o.supplier_id = s.supplier_id;

-- Orders -> Carriers
SELECT COUNT(*) AS total_orders,
       COUNT(c.carrier_id) AS matched_carriers,
       COUNT(*) - COUNT(c.carrier_id) AS unmatched_carriers
FROM read_csv_auto('data/raw/orders.csv') AS o
LEFT JOIN read_csv_auto('data/raw/carriers.csv') AS c
ON o.carrier_id = c.carrier_id;

-- Deliveries -> Orders
SELECT COUNT(*) AS total_deliveries,
       COUNT(o.order_id) AS matched_orders,
       COUNT(*) - COUNT(o.order_id) AS unmatched_orders
FROM read_csv_auto('data/raw/deliveries.csv') AS d
LEFT JOIN read_csv_auto('data/raw/orders.csv') AS o
ON d.order_id = o.order_id;

SELECT d.delivery_id, d.order_id
FROM read_csv_auto('data/raw/deliveries.csv') AS d
LEFT JOIN read_csv_auto('data/raw/orders.csv') AS o
ON d.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 5. COMPLETENESS - ORDERS
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
    COUNT(*) FILTER (WHERE warehouse_id IS NULL) AS null_warehouse_id,
    COUNT(*) FILTER (WHERE supplier_id IS NULL) AS null_supplier_id,
    COUNT(*) FILTER (WHERE carrier_id IS NULL) AS null_carrier_id,
    COUNT(*) FILTER (WHERE quantity IS NULL) AS null_quantity,
    COUNT(*) FILTER (WHERE unit_price IS NULL) AS null_unit_price,
    COUNT(*) FILTER (WHERE order_value IS NULL) AS null_order_value,
    COUNT(*) FILTER (WHERE status IS NULL) AS null_status
FROM read_csv_auto('data/raw/orders.csv');


-- 6. BUSINESS RULES - ORDERS

-- Quantity must be greater than zero
SELECT COUNT(*) AS invalid_quantity
FROM read_csv_auto('data/raw/orders.csv')
WHERE quantity <= 0;

SELECT *
FROM read_csv_auto('data/raw/orders.csv')
WHERE quantity <= 0;

-- Unit price must not be negative
SELECT COUNT(*) AS invalid_unit_price
FROM read_csv_auto('data/raw/orders.csv')
WHERE unit_price < 0;

SELECT *
FROM read_csv_auto('data/raw/orders.csv')
WHERE unit_price < 0;

-- Order value should equal quantity * unit price
SELECT COUNT(*) AS inconsistent_order_value
FROM read_csv_auto('data/raw/orders.csv')
WHERE ABS(order_value - (quantity * unit_price)) > 0.01;

SELECT order_id, quantity, unit_price, order_value,
       quantity * unit_price AS calculated_value
FROM read_csv_auto('data/raw/orders.csv')
WHERE ABS(order_value - (quantity * unit_price)) > 0.01;

-- Status profiling
SELECT status, COUNT(*) AS occurrences
FROM read_csv_auto('data/raw/orders.csv')
GROUP BY status ORDER BY occurrences DESC;


-- 7. DELIVERIES - COMPLETENESS
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE delivery_id IS NULL) AS null_delivery_id,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE promised_delivery_date IS NULL) AS null_promised_date,
    COUNT(*) FILTER (WHERE actual_delivery_date IS NULL) AS null_actual_date,
    COUNT(*) FILTER (WHERE transport_cost IS NULL) AS null_transport_cost,
    COUNT(*) FILTER (WHERE delivery_status IS NULL) AS null_delivery_status
FROM read_csv_auto('data/raw/deliveries.csv');


-- 8. DELIVERIES - TRANSPORT COST
SELECT COUNT(*) AS null_transport_cost
FROM read_csv_auto('data/raw/deliveries.csv')
WHERE transport_cost IS NULL;

SELECT COUNT(*) AS invalid_transport_cost
FROM read_csv_auto('data/raw/deliveries.csv')
WHERE transport_cost < 0;


-- 9. DELIVERIES - DATE VALIDATION
SELECT d.delivery_id, d.order_id, o.order_date, d.actual_delivery_date
FROM read_csv_auto('data/raw/deliveries.csv') AS d
JOIN read_csv_auto('data/raw/orders.csv') AS o
ON d.order_id = o.order_id
WHERE d.actual_delivery_date < o.order_date;

SELECT COUNT(*) AS invalid_delivery_dates
FROM read_csv_auto('data/raw/deliveries.csv') AS d
JOIN read_csv_auto('data/raw/orders.csv') AS o
ON d.order_id = o.order_id
WHERE d.actual_delivery_date < o.order_date;


-- 10. DELIVERIES - CARDINALITY
SELECT order_id, COUNT(*) AS delivery_count
FROM read_csv_auto('data/raw/deliveries.csv')
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY delivery_count DESC;

SELECT COUNT(*) AS orders_with_multiple_deliveries
FROM (
    SELECT order_id
    FROM read_csv_auto('data/raw/deliveries.csv')
    GROUP BY order_id
    HAVING COUNT(*) > 1
);


-- END OF PHASE 2
