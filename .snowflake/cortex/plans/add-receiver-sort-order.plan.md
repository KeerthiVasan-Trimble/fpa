# Plan: Add Receiver SORT_ORDER Column

## Problem
All downstream tables/views sort by `RECEIVER_CODE` alphabetically, giving no control over receiver display order. The user wants a canonical order defined once in `DYNAMIC_AG_RECEIVERS_LIST` and used everywhere.

## Approach

### 1. Modify `Ag Receiver List.sql`
Add a `SORT_ORDER` column using `ROW_NUMBER()` based on the Sigma writeback's `ROW_VERSION` (the order receivers were entered):

```sql
CREATE OR REPLACE DYNAMIC TABLE FIELD_SYSTEMS_EDW.USER_INPUT.DYNAMIC_AG_RECEIVERS_LIST
(
    RECEIVER_CODE,
    SORT_ORDER
)
LAG = '1 minute'
REFRESH_MODE = 'FULL'
INITIALIZE = 'ON_CREATE'
WAREHOUSE = FIELD_SYSTEMS_GENERAL_WAREHOUSE
AS
SELECT
    "MP8XAYVAWI" AS RECEIVER_CODE,
    ROW_NUMBER() OVER (ORDER BY MIN(ROW_VERSION)) AS SORT_ORDER
FROM FIELD_SYSTEMS_EDW.SIGMA_WRITEBACK."SIGDS_50f8c004_1da0_4186_b452_ce018ecdf8b4"
WHERE "MP8XAYVAWI" IS NOT NULL
  AND TOMBSTONE_VERSION IS NULL
GROUP BY "MP8XAYVAWI"
```

This gives deterministic ascending numbers (1, 2, 3...) based on when each receiver was first created in Sigma.

### 2. Update 4 Consolidated Views
These files UNION actuals + forecast and ORDER BY RECEIVER_CODE. Pattern change — wrap in CTE, LEFT JOIN to receivers list:

| File | Object |
|------|--------|
| `02 Billings/Ag Bottoms Up Billings Consolidated.sql` | VIEW_AG_BOTTOMS_UP_BILLINGS_CONSOLIDATED |
| `03 PCS Carveout/Ag PCS Consolidated.sql` | VIEW_AG_PCS_CONSOLIDATED |
| `04 RTX Carveout/Ag RTX Consolidated.sql` | VIEW_AG_RTX_CONSOLIDATED |
| `06 Dcogs Expenditure/Ag Dcogs Consolidated.sql` | VIEW_AG_DCOGS_CONSOLIDATED |

Example pattern (Billings):
```sql
-- Add as final CTE:
combined AS (
    SELECT ... FROM actuals
    UNION ALL
    SELECT ... FROM forecast
)
SELECT c.BILLING_MONTH, c.RECEIVER_CODE, c.REVENUE, c.SOURCE
FROM combined c
LEFT JOIN FIELD_SYSTEMS_EDW.USER_INPUT.DYNAMIC_AG_RECEIVERS_LIST r
    ON UPPER(c.RECEIVER_CODE) = UPPER(r.RECEIVER_CODE)
ORDER BY r.SORT_ORDER, c.BILLING_MONTH
```

LEFT JOIN handles the `'UNIFIED'` receiver in PCS/RTX actuals (which won't match — sorts last via NULL).

### 3. Update 2 Amortized Summary Views
Simple JOIN addition since these already GROUP BY RECEIVER_CODE:

| File | Object |
|------|--------|
| `03 PCS Carveout/Ag PCS Amortized Summary.sql` | VIEW_AG_PCS_AMORTIZED_SUMMARY |
| `04 RTX Carveout/Ag RTX Amortized Summary.sql` | VIEW_AG_RTX_AMORTIZED_SUMMARY |

```sql
-- Add JOIN:
JOIN FIELD_SYSTEMS_EDW.USER_INPUT.DYNAMIC_AG_RECEIVERS_LIST r
    ON src.RECEIVER_CODE = r.RECEIVER_CODE
-- Change ORDER BY:
ORDER BY r.SORT_ORDER, TARGET_MONTH
```

### 4. Update 2 Amortized Forecast Dynamic Tables
Same JOIN pattern for the final SELECT:

| File | Object |
|------|--------|
| `03 PCS Carveout/Ag PCS Amortized Forecast.sql` | DYNAMIC_AG_PCS_AMORTIZED_FORECAST |
| `04 RTX Carveout/Ag RTX Amortized Forecast.sql` | DYNAMIC_AG_RTX_AMORTIZED_FORECAST |

These already have complex CTEs. Add a JOIN to receivers list in the final SELECT and change ORDER BY.

## Files Changed (9 total)
1. `3 AgIS/02 Billings/Ag Receiver List.sql` — add SORT_ORDER column
2. `3 AgIS/02 Billings/Ag Bottoms Up Billings Consolidated.sql` — ORDER BY SORT_ORDER
3. `3 AgIS/03 PCS Carveout/Ag PCS Consolidated.sql` — ORDER BY SORT_ORDER
4. `3 AgIS/04 RTX Carveout/Ag RTX Consolidated.sql` — ORDER BY SORT_ORDER
5. `3 AgIS/06 Dcogs Expenditure/Ag Dcogs Consolidated.sql` — ORDER BY SORT_ORDER
6. `3 AgIS/03 PCS Carveout/Ag PCS Amortized Summary.sql` — ORDER BY SORT_ORDER
7. `3 AgIS/04 RTX Carveout/Ag RTX Amortized Summary.sql` — ORDER BY SORT_ORDER
8. `3 AgIS/03 PCS Carveout/Ag PCS Amortized Forecast.sql` — ORDER BY SORT_ORDER
9. `3 AgIS/04 RTX Carveout/Ag RTX Amortized Forecast.sql` — ORDER BY SORT_ORDER

## No Changes Needed
- `Ag Billing Month.sql` — CROSS JOINs receivers but has no ORDER BY
- `Ag Receiver Unit Price.sql` / `Ag Receiver Unit Sales.sql` — FULL JOIN to receivers but no ORDER BY on receiver
- Any file that JOINs on RECEIVER_CODE without ordering by it
