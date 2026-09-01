# Plan: Fix PCS Amortized Forecast Logic

## Current Behavior (what's wrong)

1. **TOTAL_WEEKS includes the 28th month** when `HALF_MONTH = TRUE` — it should only sum weeks from the 27 future months.
2. **Month 28 allocation uses its own weeks** (`28th_month_weeks * rate / 2`) — it should mirror month 1's dollar amount exactly.

## Target Behavior

For each `(RECEIVER_CODE, BILLING_MONTH)` row:

| Step | Logic |
|------|-------|
| **Start month** | `BILLING_SEQ + MONTH_LAG + 1` (current month offset by lag) |
| **Month range** | Next `MONTHS_IN_FUTURE` (27) fiscal months from start |
| **TOTAL_WEEKS** | Sum of `WEEKS_IN_MONTH` for months 1–27 only |
| **Rate** | `CARVEOUT_AMOUNT / TOTAL_WEEKS` |
| **Normal month** (2–27) | `Rate * WEEKS_IN_MONTH` |
| **Month 1** (half-month) | `Rate * month_1_WEEKS / 2` |
| **Month 28** (half-month) | Same dollar amount as month 1 = `Rate * month_1_WEEKS / 2` |
| **Month 1** (no half-month) | Normal allocation |

## Changes to `Ag PCS Amortized Forecast.sql`

### CTE: `expanded`
- Split into two parts:
  - **`core_months`**: months 1–27 (`BETWEEN billing_seq + lag + 1 AND billing_seq + lag + MONTHS_IN_FUTURE`). Compute `TOTAL_WEEKS` here (sum over months 1–27 only).
  - **`half_month_extra`**: month 28 only, when `HALF_MONTH = 'TRUE'`. Joined to get month 1's `WEEKS_IN_MONTH` for mirroring.

### Final SELECT
- For `core_months` rows: same formula as today for months 2–27; month 1 gets `/2` when `HALF_MONTH`.
- For `half_month_extra` row: amount = month 1's halved amount (uses month 1's weeks, not month 28's).

### No other files change
- `CONFIGURATION_AG_PCS` and `DYNAMIC_AG_PCS_CARVEOUT_FORECAST` are untouched.
- Column list of the dynamic table stays the same.
