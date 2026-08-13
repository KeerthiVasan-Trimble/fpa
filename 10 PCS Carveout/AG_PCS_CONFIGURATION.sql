-- PCS carveout configuration, dynamic table, amortization UDF, and summary view
-- Co-authored with CoCo

USE DATABASE FIELD_SYSTEMS_EDW;
USE SCHEMA GENERAL;

USE ROLE FIELD_SYSTEMS_DEVELOPER_ROLE;
USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;

---------------------------------------------------------------------
-- 1. PCS_CONFIG
-- Configuration table for PCS carveouts.
-- Dollar_per_unit and Carve_Percentage are mutually exclusive.
-- Includes amortization parameters: MONTHS_IN_FUTURE, HALF_MONTH, LAG_MONTH.
---------------------------------------------------------------------
CREATE OR REPLACE TABLE AG_PCS_CONFIGURATION (
    RECEIVER_CODE       VARCHAR(20),
    BILLING_MONTH       VARCHAR(20),
    DOLLAR_PER_UNIT     NUMBER(10, 3),
    CARVE_PERCENTAGE    NUMBER(10, 2),
    OTHER_BA            NUMBER(38, 0),
    NATURAL_ACCOUNT     NUMBER(38, 0),
    MONTHS_IN_FUTURE    NUMBER(10, 0),
    HALF_MONTH          BOOLEAN,
    LAG_MONTH           NUMBER(10, 0),
    CONSTRAINT CHK_PCS_MUTUAL_EXCLUSIVITY CHECK (
        (CARVE_PERCENTAGE IS NOT NULL AND DOLLAR_PER_UNIT IS NULL)
        OR (CARVE_PERCENTAGE IS NULL AND DOLLAR_PER_UNIT IS NOT NULL)
    )
);

-- Seed all receivers: $92.23 per unit, 27 months amortization
-- HALF_MONTH and LAG_MONTH values match RTX_CONFIGURATION per receiver
INSERT INTO AG_PCS_CONFIGURATION (RECEIVER_CODE, BILLING_MONTH, DOLLAR_PER_UNIT, CARVE_PERCENTAGE, OTHER_BA, NATURAL_ACCOUNT, MONTHS_IN_FUTURE, HALF_MONTH, LAG_MONTH)
VALUES
    ('NAV-900', '2026-08', 92.230, NULL, 533, 40012, 27, TRUE,  1),
    ('NAV-500', '2026-08', 92.230, NULL, 533, 40012, 27, FALSE, 0),
    ('AG-200',  '2026-08', 92.230, NULL, 533, 40012, 27, TRUE,  3),
    ('AG-392',  '2026-08', 92.230, NULL, 533, 40012, 27, FALSE, 0),
    ('AG-482',  '2026-08', 92.230, NULL, 533, 40012, 27, FALSE, 0),
    ('NAV-860', '2026-08', 92.230, NULL, 533, 40012, 27, FALSE, 0),
    ('NAV-960', '2026-08', 92.230, NULL, 533, 40012, 27, TRUE,  1),
    ('NAV-III', '2026-08', 92.230, NULL, 533, 40012, 27, FALSE, 0),
    ('TERRIER AG-960', '2026-08', 92.230, NULL, 533, 40012, 27, FALSE, 0),
    ('Z - MSDA','2026-08', 92.230, NULL, 533, 40012, 27, FALSE, 0);
