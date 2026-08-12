-- PCS carveout configuration, dynamic table, amortization UDF, and summary view
-- Co-authored with CoCo

USE DATABASE FIELD_SYSTEMS_EDW;
USE SCHEMA GENERAL;

USE ROLE FIELD_SYSTEMS_DEVELOPER_ROLE;
USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;
---------------------------------------------------------------------
-- 3. AMORTIZED_PCS (Table UDF)
-- Spreads PCS carveout amounts across future months based on
-- MONTHS_IN_FUTURE, HALF_MONTH, and LAG_MONTH from PCS_CONFIG.
---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FIELD_SYSTEMS_EDW.GENERAL.AMORTIZED_PCS()
RETURNS TABLE (
    CURRENT_MONTH VARCHAR,
    CARVEOUT FLOAT,
    OTHER_BA NUMBER,
    NATURAL_ACCOUNT NUMBER,
    CARVEOUT_FC FLOAT,
    TARGET_MONTH DATE
)
LANGUAGE SQL
AS
$$
    WITH carveout_base AS (
        SELECT
            c.RECEIVER_NAME AS RECEIVER_CODE,
            c.BILLING_MONTH AS CURRENT_MONTH,
            c.CARVEOUT_AMOUNT AS CARVEOUT,
            c.OTHER_BA,
            c.NATURAL_ACCOUNT,
            p.MONTHS_IN_FUTURE,
            p.HALF_MONTH,
            p.LAG_MONTH
        FROM FIELD_SYSTEMS_EDW.GENERAL.DYNAMIC_AG_PCS_CARVEOUTS c
        JOIN FIELD_SYSTEMS_EDW.GENERAL.PCS_CONFIG p
            ON c.RECEIVER_NAME = p.RECEIVER_CODE
            AND c.BILLING_MONTH = p.BILLING_MONTH
    ),
    fiscal_months AS (
        SELECT
            FISCAL_MONTH_START AS MONTH_START,
            ROW_NUMBER() OVER (ORDER BY FISCAL_MONTH_START) AS MONTH_SEQ
        FROM (
            SELECT DISTINCT FISCAL_MONTH_START
            FROM FIELD_SYSTEMS_EDW.GENERAL.DIMENSION_FISCAL_CALENDAR
            WHERE FISCAL_MONTH_START >= (
                SELECT FISCAL_MONTH_START
                FROM FIELD_SYSTEMS_EDW.GENERAL.DIMENSION_FISCAL_CALENDAR
                WHERE CALENDAR_DATE = CURRENT_DATE()
            )
        )
    ),
    expanded AS (
        SELECT
            cb.RECEIVER_CODE,
            cb.CURRENT_MONTH,
            cb.CARVEOUT,
            cb.OTHER_BA,
            cb.NATURAL_ACCOUNT,
            cb.HALF_MONTH,
            cb.MONTHS_IN_FUTURE,
            ROUND(cb.CARVEOUT / cb.MONTHS_IN_FUTURE, 2) AS BASE_AMOUNT,
            fm.MONTH_START,
            fm.MONTH_SEQ - cb.LAG_MONTH AS MONTH_NUMBER
        FROM carveout_base cb
        JOIN fiscal_months fm
            ON fm.MONTH_SEQ BETWEEN cb.LAG_MONTH + 1
                                  AND cb.LAG_MONTH + cb.MONTHS_IN_FUTURE + IFF(cb.HALF_MONTH, 1, 0)
    )
    SELECT
        CURRENT_MONTH,
        CARVEOUT,
        OTHER_BA,
        NATURAL_ACCOUNT,
        CASE
            WHEN HALF_MONTH AND MONTH_NUMBER = 1 THEN ROUND(BASE_AMOUNT / 2, 2)
            WHEN HALF_MONTH AND MONTH_NUMBER = MONTHS_IN_FUTURE + 1 THEN ROUND(BASE_AMOUNT / 2, 2)
            ELSE BASE_AMOUNT
        END AS CARVEOUT_FC,
        MONTH_START AS TARGET_MONTH
    FROM expanded
    ORDER BY RECEIVER_CODE, CURRENT_MONTH, MONTH_START
$$;