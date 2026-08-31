# Plan: NULL-to-Zero for All AgIS SQL Files

## Analysis Summary

Scanned all 52 SQL files in `3 AgIS/`. **40 files need no changes** (they either have no arithmetic, use only aggregations like SUM which handle NULLs natively, or are already properly wrapped). **12 files need edits** (1 already done from earlier).

## Files Already Fixed
- `Ag PCS Amortized Forecast.sql` — fixed in previous conversation turn

## Files Requiring Changes

### Task 1: `01 Revenue/Ag Other Revenue Actuals.sql`
**Line 23:** `SUM(r.REVENUE)` inside `ABS()` is not COALESCE-wrapped while the other operand is.
```sql
-- Before:
COALESCE(SUM(b.TOTAL_BILLINGS), 0) - ABS(SUM(r.REVENUE)) AS TOTAL_CARVEOUT
-- After:
COALESCE(SUM(b.TOTAL_BILLINGS), 0) - ABS(COALESCE(SUM(r.REVENUE), 0)) AS TOTAL_CARVEOUT
```

### Task 2: `02 Billings/Ag Bottoms Up Billings Forecast.sql`
**Line 23:** Both TRY_CAST operands in multiplication unprotected.
```sql
-- Before:
TRY_CAST(p.UNIT_PRICE AS NUMBER(10,2)) * TRY_CAST(s.UNITS_SOLD AS NUMBER(10,2)) AS BILLING_TOTAL
-- After:
COALESCE(TRY_CAST(p.UNIT_PRICE AS NUMBER(10,2)), 0) * COALESCE(TRY_CAST(s.UNITS_SOLD AS NUMBER(10,2)), 0) AS BILLING_TOTAL
```

### Task 3: `03 PCS Carveout/Ag PCS Carveout Forecast.sql`
**Lines 33-34:** Multiplication operands from LEFT JOINs.
```sql
-- Before (line 33):
END * r.BILLING_TOTAL
-- After:
END * COALESCE(r.BILLING_TOTAL, 0)

-- Before (line 34):
ELSE p.RATE_PER_UNIT * s.UNITS_SOLD
-- After:
ELSE COALESCE(p.RATE_PER_UNIT, 0) * COALESCE(s.UNITS_SOLD, 0)
```

### Task 4: `04 RTX Carveout/Ag RTX Carveout Forecast.sql`
**Lines 33-34:** Same pattern as PCS Carveout Forecast.
```sql
-- Wrap r.BILLING_TOTAL and s.UNITS_SOLD with COALESCE(..., 0)
```

### Task 5: `04 RTX Carveout/Ag RTX Amortized Forecast.sql`
**Lines 90, 92, 93:** Division by TOTAL_WEEKS needs NULLIF; CARVEOUT_AMOUNT and WEEKS_IN_MONTH need COALESCE in CTE.
- Wrap `c.CARVEOUT_AMOUNT` with `COALESCE(..., 0)` in carveout_base CTE
- Wrap `p.MONTHS_IN_FUTURE` with `COALESCE(..., 0)` in carveout_base CTE
- Wrap `fm.WEEKS_IN_MONTH` with `COALESCE(..., 0)` in expanded CTE
- Wrap `TOTAL_WEEKS` SUM with `COALESCE(..., 0)` in expanded CTE
- Use `NULLIF(TOTAL_WEEKS, 0)` in all three division expressions

### Task 6: `06 Dcogs Expenditure/` (2 files)
**Ag Dcogs Forecast.sql lines 25, 27:** Wrap `r.BILLING_TOTAL` and `u.UNITS_SOLD` with COALESCE.
**Ag Dcogs Actuals.sql line 15:** Wrap `d.MAXIMUM_DIRECT_COST` with COALESCE.

### Task 7: `07 Intech Carveout/` and `08 Ocogs Expenditure/` (2 files)
**Ag Intech Forecast.sql lines 27, 29:** Wrap `r.BILLING_TOTAL` and `s.UNITS_SOLD` with COALESCE.
**Ag OCogs Forecast.sql line 20:** Wrap `r.TOTAL_REVENUE` with COALESCE.

### Task 8: `05 Total Revenue/` and `12 Operating Income/` (3 files)
**Ag Total Revenue Forecast.sql line 16:** Defensive COALESCE on all 5 arithmetic operands.
**Ag Operating Income Actuals.sql line 20:** Wrap `r.REVENUE` with COALESCE (other two already wrapped).
**Ag Operating Income Forecast.sql line 20:** Wrap both `r.TOTAL_REVENUE` and `c.TOTAL_AMOUNT` with COALESCE.

## Approach
- Apply `COALESCE(column, 0)` to every column participating in `+`, `-`, `*` that could be NULL
- Apply `NULLIF(column, 0)` to every column used as a division denominator (to avoid divide-by-zero after COALESCE turns NULLs to 0)
- Prefer wrapping at the earliest CTE level when the column is reused downstream
- Leave SUM/COUNT/MAX aggregations alone (they handle NULLs natively)
