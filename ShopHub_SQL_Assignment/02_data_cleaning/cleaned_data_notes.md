# cleaned_data_notes.md

Summary of cleaning steps and assumptions

1. Duplicates
- Removed duplicate customers based on customer_unique_id using ROW_NUMBER().
- Kept the first occurrence ordered by customer_id (assumes older records have smaller IDs).

2. Geolocation
- Consolidated geolocation rows by zip prefix, keeping minimum id/values as representative coordinates.

3. Null categories
- Product rows with NULL product_category_name flagged; plan to impute category using NLP or mark as 'unknown' if not possible.

4. Timestamps
- Invalid timestamp sequences (delivered before purchase) flagged for manual review; kept records but added flag column in ETL if needed.

5. Orphans
- Orphan order_items and orders were identified. Recommended actions:
  - Reconcile with raw CSVs
  - If truly orphaned, move to an 'exceptions' table for audit rather than deleting.

Assumptions:
- customer_unique_id is the true customer identifier.
- No external enrichment performed.
