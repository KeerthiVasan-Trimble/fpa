# Plan: Standardize BILLING_MONTH to YYYY-MM Format

## Problem
Billing month columns across AgIS have three different formats:
- **`2026-M01`** (YYYY-MNN) — actuals from IDW/billings sources
- **`202601`** (YYYYMM) — some OCOGS actuals
- **`2026-01`** (YYYY-MM) — all forecast tables

Consolidated views paper over this by converting forecast → `YYYY-MNN` at display time, but the inconsistency makes joins fragile and confusing.

## Target
All `BILLING_MONTH` columns output **`2026-01`** (YYYY-MM) format. No format conversions in consolidated views.

## Universal Conversion Formula
```sql
LEFT(x, 4) || '-' || RIGHT(x, 2)
```
Works for all three source formats → `YYYY-MM`.

## Phase 1: Root Actuals (8 files)

Convert the SELECT output column only. WHERE clauses comparing raw `"Fiscal Month"` to `FISCAL_MONTH_CODE` still work since both sides remain YYYY-MNN there.

| # | File | Object | Change |
|---|------|--------|--------|
| 1 | `01 Revenue/Ag Revenue Actuals.sql` | `DYNAMIC_AG_REVENUE_ACTUALS` | `REPLACE(e."Fiscal Month", '-M', '-') AS "Fiscal Month"` |
| 2 | `01 Revenue/Ag Other Revenue Actuals.sql` | `DYNAMIC_AG_OTHER_REVENUE_ACTUALS` | Convert `FISCAL_MONTH_CODE` output to YYYY-MM; also fix the REPLACE join for billings |
| 3 | `02 Billings/Ag Bottoms Up Billings Actuals.sql` | `VIEW_AG_BOTTOMS_UP_BILLINGS_ACTUALS` | `REPLACE(b."Fiscal Month", '-M', '-') AS BILLINGS_MONTH` |
| 4 | `03 PCS/Ag PCS Actuals.sql` | `DYNAMIC_AG_PCS_ACTUALS` | `REPLACE(e."Fiscal Month", '-M', '-') AS "Fiscal Month"` |
| 5 | `04 RTX/Ag RTX Actuals.sql` | `DYNAMIC_AG_RTX_ACTUALS` | `REPLACE(e."Fiscal Month", '-M', '-') AS "Fiscal Month"` |
| 6 | `06 Dcogs/Ag Dcogs Actuals Margin.sql` | `DYNAMIC_AG_DCOGS_ACTUALS_MARGIN` | `REPLACE(b."Fiscal Month", '-M', '-') AS BILLING_MONTH` |
| 7 | `08 Ocogs/Ag OCogs Actuals.sql` | `AG_OCOGS_ACTUALS` | `LEFT(e."Fiscal Month", 4) \|\| '-' \|\| RIGHT(e."Fiscal Month", 2) AS BILLING_MONTH` (handles both YYYY-MNN and YYYYMM) |
| 8 | `10 Opex/Ag Opex Actuals.sql` | `AG_OPEX_ACTUALS` | `LEFT(e."Fiscal Month", 4) \|\| '-' \|\| RIGHT(e."Fiscal Month", 2) AS BILLING_MONTH` |

## Phase 2: Fix Downstream Joins (1 file)

| File | Object | Change |
|------|--------|--------|
| `06 Dcogs/Ag Dcogs Actuals.sql` | `AG_DCOGS_ACTUALS` | Join condition `b."Fiscal Month" = d.BILLING_MONTH` breaks because `b."Fiscal Month"` is still YYYY-MNN but `d.BILLING_MONTH` is now YYYY-MM. Fix: `REPLACE(b."Fiscal Month", '-M', '-') = d.BILLING_MONTH` |

## Phase 3: Simplify Workflow Actuals (3 files)

| File | Object | Change |
|------|--------|--------|
| `09 Total Cogs/Ag Total Cogs Actuals.sql` | `DYNAMIC_AG_TOTAL_COGS_ACTUALS` | Remove `LEFT\|\|'-M'\|\|RIGHT` on OCOGS BILLING_MONTH — now YYYY-MM natively |
| `11 Total Opex/Ag Total Opex Actuals.sql` | `DYNAMIC_AG_OPEX_ACTUALS` | No change needed — pass-through from AG_OPEX_ACTUALS which is now YYYY-MM |
| `12 Operating Income/Ag Operating Income Actuals.sql` | `DYNAMIC_OPERATING_INCOME_ACTUALS` | Remove `LEFT\|\|'-M'\|\|RIGHT` conversion on OPEX join — now YYYY-MM natively. Also update Revenue join since DYNAMIC_AG_REVENUE_ACTUALS."Fiscal Month" is now YYYY-MM |

## Phase 4: Simplify Consolidated Views (8 files)

In each view, two changes:
1. **current_period CTE**: Convert `FISCAL_MONTH_CODE` to YYYY-MM
   ```sql
   SELECT DISTINCT LEFT(FISCAL_MONTH_CODE, 4) || '-' || RIGHT(FISCAL_MONTH_CODE, 2) AS FISCAL_MONTH_CODE
   ```
2. **forecast CTE**: Remove `LEFT(BILLING_MONTH, 4) || '-M' || RIGHT(BILLING_MONTH, 2)` — use `BILLING_MONTH` directly

| File | Object |
|------|--------|
| `02 Billings/Ag Bottoms Up Billings Consolidated.sql` | `VIEW_AG_BOTTOMS_UP_BILLINGS_CONSOLIDATED` |
| `03 PCS/Ag PCS Consolidated.sql` | `VIEW_AG_PCS_CONSOLIDATED` |
| `04 RTX/Ag RTX Consolidated.sql` | `VIEW_AG_RTX_CONSOLIDATED` |
| `05 Total Revenue/Ag Total Revenue Consolidated.sql` | `VIEW_AG_TOTAL_REVENUE_CONSOLIDATED` |
| `06 Dcogs/Ag Dcogs Consolidated.sql` | `VIEW_AG_DCOGS_CONSOLIDATED` |
| `09 Total Cogs/Ag Total Cogs Consolidated.sql` | `VIEW_AG_TOTAL_COGS_CONSOLIDATED` |
| `11 Total Opex/Ag Total Opex Consolidated.sql` | `VIEW_AG_OPEX_CONSOLIDATED` |
| `12 Operating Income/Ag Operating Income Consolidated.sql` | `VIEW_AG_OPERATING_INCOME_CONSOLIDATED` |

## Phase 5: Deploy & Verify

Deploy in dependency order:
1. Root actuals DTs (Phase 1)
2. AG_DCOGS_ACTUALS (Phase 2 — depends on DCOGS_ACTUALS_MARGIN)
3. Workflow actuals DTs (Phase 3 — depend on root actuals)
4. Consolidated views (Phase 4 — depend on everything above)

Spot-check each object to confirm YYYY-MM format.

## Out of Scope
- Forecast tables (already YYYY-MM — no changes needed)
- Configuration tables (already YYYY-MM)
- Waterfall views (use YYYY-MNN as column headers — different concern)
- `DYNAMIC_AG_OTHER_REVENUE_ACTUALS` complex billings join (flag for review)
