# Data Quality Matrix

## Supply Chain BI Project

| Rule ID | Dimension | Table | Rule | Violations | Severity | Treatment |
|---|---|---|---|---:|---|---|
| DQ-001 | Uniqueness | orders | order_id must be unique | 80 | Critical | Deduplicate in staging |
| DQ-002 | Uniqueness | deliveries | delivery_id must be unique | 50 | Critical | Deduplicate in staging |
| DQ-003 | Completeness | orders | customer_id should be populated | 120 | Medium | Map to unknown customer |
| DQ-004 | Referential Integrity | orders | customer_id must exist in customers | 50 | High | Map/quarantine according to business rule |
| DQ-005 | Validity | orders | quantity must be > 0 | 60 | High | Flag and investigate |
| DQ-006 | Consistency | orders | order_value = quantity * unit_price | 60 | High | Investigate root cause |
| DQ-007 | Standardization | orders | status must use controlled vocabulary | 100 | Medium | Normalize in staging |
| DQ-008 | Completeness | deliveries | transport_cost should be populated | 100 | Medium | Flag missing value |
| DQ-009 | Validity | deliveries | actual_delivery_date >= order_date | 75 | High | Flag and investigate |
| DQ-010 | Cardinality | deliveries | Multiple deliveries per order require business validation | 50 | Low | Investigated as duplicate delivery records |

## Root Cause Assessment

### DQ-005 / DQ-006

60 orders contain negative quantities.

The corresponding `order_value` matches:

`ABS(quantity) * unit_price`

This indicates that the two quality violations are related to the same underlying anomaly.

The exact source-system root cause is not confirmed from the available dataset.

Possible explanations include:

- source-system sign error;
- return/adjustment transaction represented as a negative quantity;
- undocumented transaction type.

No automatic correction should be applied without business confirmation.

### DQ-003 / DQ-004

Customer issues consist of:

- 120 orders with NULL customer_id;
- 50 orders with an orphan customer_id.

These represent different data quality dimensions:

- completeness;
- referential integrity.

Orders should not be removed solely because customer information is missing.

The analytical model should provide an explicit unknown/generic customer strategy.

### DQ-002 / DQ-010

The 50 orders with multiple delivery rows were investigated.

Each affected order has:

- 2 delivery rows;
- 1 distinct delivery_id.

Therefore, the observed multiplicity is caused by duplicate delivery records rather than evidence of legitimate multiple shipments.

These records are candidates for deduplication in the staging layer.

## Data Governance Principle

Raw data must remain immutable.

Corrections and standardizations are applied downstream in the staging layer and must be:

1. reproducible;
2. documented;
3. traceable;
4. based on explicit business rules.
