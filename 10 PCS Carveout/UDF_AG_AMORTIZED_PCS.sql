---------------------------------------------------------------------
-- 3. AMORTIZED_PCS_V2 (Table UDF - Parameterized)
-- Spreads a PCS carveout amount across future fiscal months.
-- Inputs: RECEIVER_CODE, BILLING_MONTH, CARVEOUT_AMOUNT,
--         MONTHS_IN_FUTURE, HALF_MONTH, LAG_MONTH
-- Logic:
--   - Divides CARVEOUT_AMOUNT evenly across MONTHS_IN_FUTURE months.
--   - If HALF_MONTH = TRUE, spreads over MONTHS_IN_FUTURE + 1 months
--     where the 1st and last month receive 50% of the per-month value.
--   - LAG_MONTH offsets the start of the amortization window.
-- Caller joins PCS_CONFIG externally to supply config values.
---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FIELD_SYSTEMS_EDW.GENERAL.AG_AMORTIZED_PCS(
    P_RECEIVER_CODE     VARCHAR,
    P_BILLING_MONTH     VARCHAR,
    P_CARVEOUT_AMOUNT   FLOAT,
    P_MONTHS_IN_FUTURE  NUMBER,
    P_HALF_MONTH        BOOLEAN,
    P_LAG_MONTH         NUMBER
)
RETURNS TABLE (
    RECEIVER_CODE   VARCHAR,
    BILLING_MONTH   VARCHAR,
    CARVEOUT        FLOAT,
    CARVEOUT_FC     FLOAT,
    TARGET_MONTH    DATE,
    MONTH_NUMBER    NUMBER
)
LANGUAGE SQL
AS
$$
    WITH all_fiscal AS (
        SELECT DISTINCT FISCAL_MONTH_START
        FROM FIELD_SYSTEMS_EDW.GENERAL.DIMENSION_FISCAL_CALENDAR
        QUALIFY FISCAL_MONTH_START >= MAX(IFF(FISCAL_MONTH_START <= CURRENT_DATE(), FISCAL_MONTH_START, NULL)) OVER ()
    ),
    fiscal_months AS (
        SELECT
            FISCAL_MONTH_START AS MONTH_START,
            ROW_NUMBER() OVER (ORDER BY FISCAL_MONTH_START) AS MONTH_SEQ
        FROM all_fiscal
    ),
    expanded AS (
        SELECT
            fm.MONTH_START,
            fm.MONTH_SEQ - P_LAG_MONTH AS MONTH_NUMBER,
            ROUND(P_CARVEOUT_AMOUNT / P_MONTHS_IN_FUTURE, 2) AS BASE_AMOUNT
        FROM fiscal_months fm
        WHERE fm.MONTH_SEQ BETWEEN P_LAG_MONTH + 1
                                AND P_LAG_MONTH + P_MONTHS_IN_FUTURE + IFF(P_HALF_MONTH, 1, 0)
    )
    SELECT
        P_RECEIVER_CODE     AS RECEIVER_CODE,
        P_BILLING_MONTH     AS BILLING_MONTH,
        P_CARVEOUT_AMOUNT   AS CARVEOUT,
        CASE
            WHEN P_HALF_MONTH AND MONTH_NUMBER = 1
                THEN ROUND(BASE_AMOUNT / 2, 2)
            WHEN P_HALF_MONTH AND MONTH_NUMBER = P_MONTHS_IN_FUTURE + 1
                THEN ROUND(BASE_AMOUNT / 2, 2)
            ELSE BASE_AMOUNT
        END AS CARVEOUT_FC,
        MONTH_START AS TARGET_MONTH,
        MONTH_NUMBER
    FROM expanded
    ORDER BY MONTH_START
$$;
