# Bottoms-Up Revenue Model – dbt Project

**Project:** `bottoms_up_dbt` · **Database / Schema:** `FIELD_SYSTEMS_EDW.GENERAL` · **Status:** Built and tested (21/21 checks passed)

---

## 1. Purpose

The project calculates Bottoms-Up (BU) revenue for each **Forecasting Group × Region × Fiscal Month**:

```
Revenue = Unit Price × Units Sold
```

Unit Price comes from the Forecasting Group's ASP. Units Sold are entered by Financial Analysts in Sigma. The calculation runs only for Forecasting Groups where `FG_TYPE = 'Bottoms_UP'` and `FG_STATUS = 'Active'`.

---

## 2. Architecture

```
 PRIMARY INPUT SOURCES
 ┌──────────────┐ ┌──────────┐ ┌────────┐ ┌───────────────────┐ ┌────────────────┐
 │Fiscal Calendar│ │ Region   │ │ Forex  │ │ Forecasting Group │ │ General Ledger │
 └──────┬───────┘ └────┬─────┘ └───┬────┘ └─────────┬─────────┘ └───────┬────────┘
        └──────────────┴───────────┴── Configuration ┴───────────────────┘
                                          │
              ┌───────────────────────────┴───────────────────────────┐
              ▼                                                       ▼
   ┌─────────── BU_UNIT_PRICE ───────────┐         ┌─────────── BU_UNIT_SALES ───────────┐
   │ FG · Region · Fiscal Month · BA · NA│         │ FG · Region · Fiscal Month · BA · NA│
   │ Unit Price · Currency               │         │ Units Sold (Sigma) · Currency       │
   │ UNIT_PRICE_CODE = FG*REGION*FC      │         │ UNIT_SALES_CODE = FG*REGION*FC      │
   └──────────────────┬──────────────────┘         └──────────────────┬──────────────────┘
                      └────────────────────┬──────────────────────────┘
                                           ▼
                    ┌────────────────── BU_REVENUE ──────────────────┐
                    │ FG · Region · Fiscal Month · BA · NA · CC · LOC│
                    │ Revenue · Currency · FX Rate · Revenue USD     │
                    │ REVENUE_CODE = FG*REGION*FC                    │
                    └────────────────────────────────────────────────┘
```

---

## 3. Source Tables

| Source | Object | Role |
|---|---|---|
| Region | `GENERAL.REGIONS` | NATAM, LATAM, EMEA, APAC, JAPAN, CANADA, UNKNOWN (7 active) |
| Forex | `GENERAL.FOREX` | Monthly rates to USD (Jul–Oct 2026) |
| Forecasting Group | `GENERAL.BU_FORECASTING_GROUP` | **New.** FG master with ASP, type, status and GL codes |
| Unit Sales (Sigma) | `GENERAL.BU_UNIT_SALES_INPUT` | **New placeholder.** Units sold per FG × Region × Month |
| Fiscal Calendar | `ARCHITECTURAL_COMPONENT.DIMENSION_FISCAL_CALENDAR` | Fiscal months (`2026-M07` → `2026-07`) |
| General Ledger | `ARCHITECTURAL_COMPONENT.DIMENSION_GL_BUSINESS_GROUP`, `_NATURAL_ACCOUNT`, `_COST_CENTER`, `_LOCATION` | BA, NA, CC, LOC codes |

### BU_FORECASTING_GROUP

| FG_ID | FG_NAME | FG_TYPE | FG_ASP | FG_STATUS | CURRENCY | BA | NA | CC | LOC |
|---|---|---|---|---|---|---|---|---|---|
| 101 | AG | Bottoms_UP | 200 | Active | USD | 553 (AgIS) | 40010 (Product Revenue – HW) | 1000 (Revenue) | 0000 |
| 102 | NAV | Bottoms_UP | 350 | Active | USD | 167 (Navigation Infrastructure) | 40010 | 1000 | 0000 |
| 103 | PCS | Top_Down | 500 | Active | USD | 560 (AG Services) | 40012 (Service Revenue) | 1000 | 0000 |

FG 101 matches the specification. FGs 102 and 103 are samples: 103 is `Top_Down`, so it is **excluded** to show the filter working.

### BU_UNIT_SALES_INPUT (Sigma target)

| Column | Type | Notes |
|---|---|---|
| FG_ID | NUMBER | FK → BU_FORECASTING_GROUP |
| REGION_ID | NUMBER | FK → REGIONS |
| BILLING_MONTH | VARCHAR(7) | `YYYY-MM` |
| UNITS_SOLD | NUMBER(18,2) | Entered by FA |
| ENTERED_BY / ENTERED_AT | audit | Defaults to the current user and time |

The table is preloaded with sample units for Jul–Dec 2026 (84 rows).

---

## 4. dbt Lineage

```
sources ─► staging (views) ─► intermediate (views) ─► marts (tables)

REGIONS ──────────────► stg_bu_region ─────────┐
BU_FORECASTING_GROUP ─► stg_bu_forecasting_group┼─► int_bu_fg_region (CROSS JOIN, Bottoms_UP only)
                                                │            │
DIMENSION_FISCAL_CALENDAR ► stg_bu_fiscal_month ┤            ▼
BU_UNIT_SALES_INPUT ──► stg_bu_unit_sales ──────┴─► int_bu_fg_region_month
                                                             │
                                          ┌──────────────────┴──────────────────┐
                                          ▼                                     ▼
                                    BU_UNIT_PRICE                         BU_UNIT_SALES
                                          └──────────────┬──────────────────────┘
FOREX ───────────► stg_bu_forex ─────────────────────────┤
                                                         ▼
                                                     BU_REVENUE
DIMENSION_GL_* ──► stg_bu_gl_codes (used by tests)
```

---

## 5. Business Logic

1. **FG filter:** only `FG_TYPE = 'Bottoms_UP'` and `FG_STATUS = 'Active'`.
2. **FG × Region cross join:** every eligible FG is paired with every active region.
   *2 FGs × 7 regions = 14 rows* (the rule from the requirement: 2 FG × 4 regions = 8).
3. **Fiscal month expansion:** each FG × Region row repeats for every fiscal month that has Sigma input. The fiscal code `2026-M07` is converted to `2026-07`.
4. **Unit Price:** `FG_ASP`, in the FG's currency.
5. **Units Sold:** taken from Sigma input. A missing entry defaults to `0`, so every FG × Region × Month row is still present.
6. **Revenue:** `Unit Price × Units Sold`.
7. **Revenue USD:** `Revenue × FOREX.AVERAGE_RATE` for the month. USD FGs use a rate of 1.
8. **Codes:** `FG_ID*REGION_CODE*FISCAL_MONTH`, e.g. `101*NATAM*2026-07`. The code is the same across Unit Price, Unit Sales and Revenue, so the three tables join on it.

---

## 6. Output Tables

| Table | Grain | Rows |
|---|---|---|
| `GENERAL.BU_UNIT_PRICE` | FG × Region × Month | 84 |
| `GENERAL.BU_UNIT_SALES` | FG × Region × Month | 84 |
| `GENERAL.BU_REVENUE` | FG × Region × Month | 84 |

Rows = 2 FG × 7 Regions × 6 months (Jul–Dec 2026).

### Worked example (from BU_REVENUE, Jul 2026, FG 101 AG)

| Revenue Code | Region | BA | NA | Unit Price | Units Sold | Revenue (USD) |
|---|---|---|---|---|---|---|
| 101\*NATAM\*2026-07 | NATAM | 553 | 40010 | 200 | 127 | 25,400 |
| 101\*LATAM\*2026-07 | LATAM | 553 | 40010 | 200 | 188 | 37,600 |
| 101\*EMEA\*2026-07 | EMEA | 553 | 40010 | 200 | 191 | 38,200 |
| 101\*APAC\*2026-07 | APAC | 553 | 40010 | 200 | 122 | 24,400 |

### Monthly summary (USD)

| Month | AG (101) | NAV (102) | Total |
|---|---|---|---|
| 2026-07 | 193,000 | 257,250 | 450,250 |
| 2026-08 | 189,200 | 373,800 | 563,000 |
| 2026-09 | 198,000 | 213,850 | 411,850 |
| 2026-10 | 167,600 | 321,650 | 489,250 |
| 2026-11 | 181,400 | 254,100 | 435,500 |
| 2026-12 | 178,000 | 298,200 | 476,200 |
| **Total** | **1,107,200** | **1,718,850** | **2,826,050** |

---

## 7. Data Quality Tests (21/21 passing)

- `unique` and `not_null` on UNIT_PRICE_CODE, UNIT_SALES_CODE and REVENUE_CODE
- `not_null` on UNITS_SOLD and REVENUE_USD
- `assert_fg_region_cross_join_count`: FG × Region rows must equal #Bottoms_UP FGs × #Regions
- `assert_fg_gl_codes_exist`: each FG's BA, NA, CC and LOC must exist in its GL dimension

---

## 8. Connecting Sigma

1. Build the Sigma input table with the columns FG_ID, REGION_ID, BILLING_MONTH (`YYYY-MM`) and UNITS_SOLD.
2. Then do one of the following:
   - **Option A:** point Sigma write-back at `GENERAL.BU_UNIT_SALES_INPUT` (no code change).
   - **Option B:** in `models/sources.yml`, change `unit_sales_input` to the Sigma table (e.g. schema `SIGMA_WRITEBACK`, identifier `SIGDS_<id>`) and map the columns in `stg_bu_unit_sales.sql`.
3. Run `dbt build`.

---

## 9. Running the Project

From the workspace:
```
dbt build --project-dir /bottoms_up_dbt
```

Deploy as a Snowflake dbt project object (optional) and schedule:
```sql
CREATE DBT PROJECT FIELD_SYSTEMS_EDW.GENERAL.BOTTOMS_UP_DBT
  FROM 'snow://workspace/user$.public."<workspace_name>"/versions/live';

EXECUTE DBT PROJECT FIELD_SYSTEMS_EDW.GENERAL.BOTTOMS_UP_DBT ARGS = 'build';
```

---

## 10. Project Files

```
bottoms_up_dbt/
├── dbt_project.yml
├── dbt_projects_profiles.yml
├── macros/generate_schema_name.sql
├── models/
│   ├── sources.yml
│   ├── schema.yml
│   ├── staging/        stg_bu_region, stg_bu_forex, stg_bu_forecasting_group,
│   │                   stg_bu_unit_sales, stg_bu_fiscal_month, stg_bu_gl_codes
│   ├── intermediate/   int_bu_fg_region, int_bu_fg_region_month
│   └── marts/          bu_unit_price, bu_unit_sales, bu_revenue
└── tests/              assert_fg_region_cross_join_count, assert_fg_gl_codes_exist
```

---

## 11. Open Questions for the Meeting

1. **ASP by region:** should Unit Price vary by Region and Month, or stay at one ASP per FG? Today it is one ASP per FG.
2. **Currency:** all FGs are in USD today. Should regional local currencies be supported (FOREX is already wired in)?
3. **FX coverage:** FOREX only has rates for Jul–Oct 2026. Nov–Dec rates are needed before any non-USD FG is used.
4. **GL codes:** should BA, NA, CC and LOC be set per FG, or per FG × Region?
5. **Missing input:** if Sigma has no units for an FG × Region × Month, should that row show 0 (current behavior) or be flagged as an exception?
6. **Versioning:** do we need snapshots per forecast version or approval cycle?
