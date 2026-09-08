/*1 - Quantidade de REGISTROS*/
SELECT COUNT(*)
FROM read_csv_auto('data/raw/orders.csv');

SELECT COUNT(*)
FROM read_csv_auto('data/raw/customers.csv');

SELECT COUNT(*)
FROM read_csv_auto('data/raw/carriers.csv');

SELECT COUNT(*)
FROM read_csv_auto('data/raw/deliveries.csv');

SELECT COUNT(*)
FROM read_csv_auto('data/raw/products.csv');

SELECT COUNT(*)
FROM read_csv_auto('data/raw/suppliers.csv');

SELECT COUNT(*)
FROM read_csv_auto('data/raw/warehouses.csv');

/*2 - Investigar PK Se tem nulas */

SELECT COUNT(*) AS total_rows,
       COUNT(order_id) AS non_null_ids,
       COUNT(*) - COUNT(order_id) AS null_ids
FROM read_csv_auto('data/raw/orders.csv');

SELECT COUNT(*) AS total_rows,
       COUNT(customer_id) AS non_null_ids,
       COUNT(*) - COUNT(customer_id) AS null_ids
FROM read_csv_auto('data/raw/customers.csv');

SELECT COUNT(*) AS total_rows,
       COUNT(carrier_id) AS non_null_ids,
       COUNT(*) - COUNT(carrier_id) AS null_ids
FROM read_csv_auto('data/raw/carriers.csv');

SELECT COUNT(*) AS total_rows,
       COUNT(delivery_id) AS non_null_ids,
       COUNT(*) - COUNT(delivery_id) AS null_ids
FROM read_csv_auto('data/raw/deliveries.csv');

SELECT COUNT(*) AS total_rows,
       COUNT(product_id) AS non_null_ids,
       COUNT(*) - COUNT(product_id) AS null_ids
FROM read_csv_auto('data/raw/products.csv');

SELECT COUNT(*) AS total_rows,
       COUNT(supplier_id) AS non_null_ids,
       COUNT(*) - COUNT(supplier_id) AS null_ids
FROM read_csv_auto('data/raw/suppliers.csv');

SELECT COUNT(*) AS total_rows,
       COUNT(warehouse_id) AS non_null_ids,
       COUNT(*) - COUNT(warehouse_id) AS null_ids
FROM read_csv_auto('data/raw/warehouses.csv');

/*3-INVESTIGAR COMPLETUDE*/
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
FROM read_csv_auto('data/raw/orders.csv');

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
FROM read_csv_auto('data/raw/customers.csv');

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE carrier_id IS NULL) AS null_carrier_id,
FROM read_csv_auto('data/raw/carriers.csv');

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE delivery_id IS NULL) AS null_delivery_id,
FROM read_csv_auto('data/raw/deliveries.csv');

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
FROM read_csv_auto('data/raw/products.csv');

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE supplier_id IS NULL) AS null_supplier_id,
FROM read_csv_auto('data/raw/suppliers.csv');

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE warehouse_id IS NULL) AS null_warehouse_id,
FROM read_csv_auto('data/raw/warehouses.csv');  

/*4 - INTEGRIDADE REFERENCIAL*/
SELECT 
    COUNT(*) AS total_orders,
    COUNT(customers.customer_id) AS matched_customers,
    COUNT(*) - COUNT(customers.customer_id) AS unmatched_customers
