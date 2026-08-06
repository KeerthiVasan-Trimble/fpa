-- Revenue amortization waterfall: creates input/output tables and computes amortized revenue by fiscal month
-- Co-authored with CoCo

-- ============================================================
-- INPUT TABLE 1: User revenue entries (one row per user per month)
-- ============================================================
CREATE OR REPLACE TABLE FIELD_SYSTEMS_EDW.GENERAL.USER_REVENUE (
    user_name     VARCHAR(50)  NOT NULL,
    current_month VARCHAR(10)  NOT NULL,
    amount        NUMBER(12,2) NOT NULL
);

INSERT INTO FIELD_SYSTEMS_EDW.GENERAL.USER_REVENUE (user_name, current_month, amount)
SELECT
    u.user_name,
    '2026-' || LPAD(m.month_num, 2, '0') AS current_month,
    u.base_amount
FROM (SELECT column1 AS user_name, column2 AS base_amount FROM VALUES
    ('Alice', 10000),
    ('Bob',   24000),
    ('Carol', 50000)
) u
CROSS JOIN (SELECT SEQ4() + 1 AS month_num FROM TABLE(GENERATOR(ROWCOUNT => 8))) m;

-- ============================================================
-- INPUT TABLE 2: Amortization schedule rules per user
-- ============================================================
CREATE OR REPLACE TABLE FIELD_SYSTEMS_EDW.GENERAL.USER_SCHEDULE (
    user_name  VARCHAR(50)  NOT NULL,
    months     NUMBER(4,0)  NOT NULL,
    lag_months NUMBER(4,0)  NOT NULL DEFAULT 0,
    half_month BOOLEAN      NOT NULL DEFAULT FALSE
);

INSERT INTO FIELD_SYSTEMS_EDW.GENERAL.USER_SCHEDULE (user_name, months, lag_months, half_month)
VALUES
    ('Alice', 10, 0, FALSE),
    ('Bob',    8, 3, TRUE),
    ('Carol',  6, 1, TRUE);

-- ============================================================
-- OUTPUT TABLE: Amortization results aggregated by user + target month
-- ============================================================
CREATE OR REPLACE TABLE FIELD_SYSTEMS_EDW.GENERAL.AMORTIZATION_OUTPUT (
    user_name      VARCHAR(50)  NOT NULL,
    target_month   DATE         NOT NULL,
    amount         NUMBER(12,2) NOT NULL,
    source_months  VARCHAR      NOT NULL
);

-- ============================================================
-- INSERT: Compute and store amortization schedule
-- ============================================================
INSERT INTO FIELD_SYSTEMS_EDW.GENERAL.AMORTIZATION_OUTPUT (user_name, target_month, amount, source_months)
WITH input_data AS (
    SELECT
        r.user_name,
        r.current_month,
        r.amount,
        s.months,
        s.lag_months,
        s.half_month,
        ROUND(r.amount / s.months, 2) AS base_amount
    FROM FIELD_SYSTEMS_EDW.GENERAL.USER_REVENUE r
    JOIN FIELD_SYSTEMS_EDW.GENERAL.USER_SCHEDULE s
      ON r.user_name = s.user_name
),
fiscal_months AS (
    SELECT
        FISCAL_MONTH_START AS month_start,
        ROW_NUMBER() OVER (ORDER BY FISCAL_MONTH_START) AS month_seq
    FROM (
        SELECT DISTINCT FISCAL_MONTH_START
        FROM FIELD_SYSTEMS_EDW.GENERAL.DIMENSION_FISCAL_CALENDAR
        WHERE FISCAL_MONTH_START >= DATE_TRUNC('MONTH', CURRENT_DATE())
    )
),
expanded AS (
    SELECT
        d.user_name,
        d.current_month,
        fm.month_start,
        d.half_month,
        d.base_amount,
        fm.month_seq - d.lag_months AS month_number,
        d.months
    FROM input_data d
    JOIN fiscal_months fm
      ON fm.month_seq BETWEEN d.lag_months + 1
                          AND d.lag_months + d.months + IFF(d.half_month, 1, 0)
),
with_amounts AS (
    SELECT
        user_name,
        current_month,
        month_start,
        CASE
            WHEN half_month AND month_number = 1          THEN ROUND(base_amount / 2, 2)
            WHEN half_month AND month_number = months + 1 THEN ROUND(base_amount / 2, 2)
            ELSE base_amount
        END AS amount
    FROM expanded
)
SELECT
    user_name,
    month_start AS target_month,
    SUM(amount) AS amount,
    LISTAGG(DISTINCT current_month, ', ') WITHIN GROUP (ORDER BY current_month) AS source_months
FROM with_amounts
GROUP BY user_name, month_start
ORDER BY user_name, month_start;

