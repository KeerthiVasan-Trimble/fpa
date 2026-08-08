USE DATABASE FIELD_SYSTEMS_EDW;
USE SCHEMA GENERAL;

USE ROLE FIELD_SYSTEMS_DEVELOPER_ROLE;
USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;



-- Fiscal Calendar dimension table with primary key, NOT NULL constraints, and column comments
-- Co-authored with CoCo

-- Create Dimension Fiscal Calendar --
CREATE OR REPLACE TABLE FIELD_SYSTEMS_EDW.GENERAL.DIMENSION_FISCAL_CALENDAR (
    DATE_KEY              NUMBER(10)    NOT NULL  COMMENT 'Surrogate key representing the date in numeric format',
    CALENDAR_DATE         DATE          NOT NULL  COMMENT 'Actual calendar date',
    DAY_OF_WEEK           NUMBER(1)     NOT NULL  COMMENT 'Day of the week (1-7)',
    FISCAL_WEEK_CODE      VARCHAR(10)   NOT NULL  COMMENT 'Fiscal week identifier code (e.g., 2026-28)',
    FISCAL_WEEK           NUMBER(2)     NOT NULL  COMMENT 'Fiscal week number within the fiscal year',
    FISCAL_WEEK_START     DATE          NOT NULL  COMMENT 'Start date of the fiscal week',
    FISCAL_WEEK_END       DATE          NOT NULL  COMMENT 'End date of the fiscal week',
    FISCAL_MONTH_CODE     VARCHAR(10)   NOT NULL  COMMENT 'Fiscal month identifier code (e.g., 2026-M06)',
    FISCAL_MONTH          NUMBER(2)     NOT NULL  COMMENT 'Fiscal month number within the fiscal year',
    FISCAL_MONTH_START    DATE          NOT NULL  COMMENT 'Start date of the fiscal month',
    FISCAL_MONTH_END      DATE          NOT NULL  COMMENT 'End date of the fiscal month',
    WEEKS_IN_MONTH        NUMBER(2)     NOT NULL  COMMENT 'Number of weeks in the fiscal month',
    FISCAL_QUARTER_CODE   VARCHAR(10)   NOT NULL  COMMENT 'Fiscal quarter identifier code (e.g., 2026-Q1)',
    FISCAL_QUARTER        NUMBER(1)     NOT NULL  COMMENT 'Fiscal quarter number (1-4)',
    FISCAL_QUARTER_START  DATE          NOT NULL  COMMENT 'Start date of the fiscal quarter',
    FISCAL_QUARTER_END    DATE          NOT NULL  COMMENT 'End date of the fiscal quarter',
    WEEKS_IN_QUARTER      NUMBER(2)     NOT NULL  COMMENT 'Number of weeks in the fiscal quarter',
    FISCAL_YEAR           NUMBER(4)     NOT NULL  COMMENT 'Fiscal year number',
    FISCAL_YEAR_START     DATE          NOT NULL  COMMENT 'Start date of the fiscal year',
    FISCAL_YEAR_END       DATE          NOT NULL  COMMENT 'End date of the fiscal year',
    WEEKS_IN_YEAR         NUMBER(2)     NOT NULL  COMMENT 'Number of weeks in the fiscal year',

    CONSTRAINT PK_DIMENSION_FISCAL_CALENDAR PRIMARY KEY (DATE_KEY)
)
COMMENT = 'Dimension table containing fiscal calendar attributes for date-based reporting';


-- Transform staging calendar data into DIMENSION_FISCAL_CALENDAR using 5-4-4 pattern
INSERT INTO FIELD_SYSTEMS_EDW.GENERAL.DIMENSION_FISCAL_CALENDAR (
    DATE_KEY,
    CALENDAR_DATE,
    DAY_OF_WEEK,
    FISCAL_WEEK_CODE,
    FISCAL_WEEK,
    FISCAL_WEEK_START,
    FISCAL_WEEK_END,
    FISCAL_MONTH_CODE,
    FISCAL_MONTH,
    FISCAL_MONTH_START,
    FISCAL_MONTH_END,
    WEEKS_IN_MONTH,
    FISCAL_QUARTER_CODE,
    FISCAL_QUARTER,
    FISCAL_QUARTER_START,
    FISCAL_QUARTER_END,
    WEEKS_IN_QUARTER,
    FISCAL_YEAR,
    FISCAL_YEAR_START,
    FISCAL_YEAR_END,
    WEEKS_IN_YEAR
)
WITH RAW_DATA AS (
    SELECT * FROM STG_RAW_CALENDAR_2030
),
CALC_WEEKS AS (
    SELECT
        CAST(TO_CHAR(CALENDAR_DATE, 'YYYYMMDD') AS INT) AS DATE_KEY,
        CALENDAR_DATE,
        -- Day of week: 1=Sat through 7=Fri (fiscal week starts Saturday)
        CASE DAYNAME(CALENDAR_DATE)
            WHEN 'Sat' THEN 1
            WHEN 'Sun' THEN 2
            WHEN 'Mon' THEN 3
            WHEN 'Tue' THEN 4
            WHEN 'Wed' THEN 5
            WHEN 'Thu' THEN 6
            WHEN 'Fri' THEN 7
        END AS DAY_OF_WEEK,
        FISCAL_YEAR || '-W' || LPAD(YTD_WEEK, 2, '0') AS FISCAL_WEEK_CODE,
        YTD_WEEK AS FISCAL_WEEK,
        QTR_WEEK,
        -- Fiscal week start (Saturday)
        DATEADD(day,
            -CASE DAYNAME(CALENDAR_DATE)
                WHEN 'Sat' THEN 0
                WHEN 'Sun' THEN 1
                WHEN 'Mon' THEN 2
                WHEN 'Tue' THEN 3
                WHEN 'Wed' THEN 4
                WHEN 'Thu' THEN 5
                WHEN 'Fri' THEN 6
            END,
            CALENDAR_DATE
        ) AS FISCAL_WEEK_START,
        -- Fiscal month number (1-12) using 5-4-4 pattern
        (CAST(RIGHT(FISCAL_QTR, 1) AS INT) - 1) * 3 +
            CASE
                WHEN QTR_WEEK <= 5 THEN 1
                WHEN QTR_WEEK <= 9 THEN 2
                ELSE 3
            END AS FISCAL_MONTH,
        -- Week number within the month
        CASE
            WHEN QTR_WEEK <= 5 THEN QTR_WEEK
            WHEN QTR_WEEK <= 9 THEN QTR_WEEK - 5
            ELSE QTR_WEEK - 9
        END AS MONTH_WEEK_NUM,
        -- Weeks in month (5-4-4 pattern, with extra week in last month of Q4 for 53-week years)
        CASE
            WHEN QTR_WEEK <= 5 THEN 5
            WHEN QTR_WEEK BETWEEN 6 AND 9 THEN 4
            ELSE
                CASE
                    WHEN MAX(YTD_WEEK) OVER (PARTITION BY FISCAL_YEAR) = 53
                         AND FISCAL_QTR = 'Q4' THEN 5
                    ELSE 4
                END
        END AS WEEKS_IN_MONTH,
        FISCAL_YEAR || '-' || FISCAL_QTR AS FISCAL_QUARTER_CODE,
        CAST(RIGHT(FISCAL_QTR, 1) AS INT) AS FISCAL_QUARTER,
        FISCAL_YEAR,
        MAX(YTD_WEEK) OVER (PARTITION BY FISCAL_YEAR) AS WEEKS_IN_YEAR,
        MAX(QTR_WEEK) OVER (PARTITION BY FISCAL_YEAR, FISCAL_QTR) AS MAX_QTR_WEEK
    FROM RAW_DATA
),
CALC_BOUNDARIES AS (
    SELECT
        DATE_KEY,
        CALENDAR_DATE,
        DAY_OF_WEEK,
        FISCAL_WEEK_CODE,
        FISCAL_WEEK,
        FISCAL_WEEK_START,
        DATEADD(day, 6, FISCAL_WEEK_START) AS FISCAL_WEEK_END,
        FISCAL_YEAR || '-M' || LPAD(FISCAL_MONTH, 2, '0') AS FISCAL_MONTH_CODE,
        FISCAL_MONTH,
        DATEADD(day, -(MONTH_WEEK_NUM - 1) * 7, FISCAL_WEEK_START) AS FISCAL_MONTH_START,
        WEEKS_IN_MONTH,
        FISCAL_QUARTER_CODE,
        FISCAL_QUARTER,
        DATEADD(day, -(QTR_WEEK - 1) * 7, FISCAL_WEEK_START) AS FISCAL_QUARTER_START,
        MAX_QTR_WEEK AS WEEKS_IN_QUARTER,
        FISCAL_YEAR,
        DATEADD(day, -(FISCAL_WEEK - 1) * 7, FISCAL_WEEK_START) AS FISCAL_YEAR_START,
        WEEKS_IN_YEAR
    FROM CALC_WEEKS
)
SELECT
    DATE_KEY,
    CALENDAR_DATE,
    DAY_OF_WEEK,
    FISCAL_WEEK_CODE,
    FISCAL_WEEK,
    FISCAL_WEEK_START,
    FISCAL_WEEK_END,
    FISCAL_MONTH_CODE,
    FISCAL_MONTH,
    FISCAL_MONTH_START,
    DATEADD(day, (WEEKS_IN_MONTH * 7) - 1, FISCAL_MONTH_START) AS FISCAL_MONTH_END,
    WEEKS_IN_MONTH,
    FISCAL_QUARTER_CODE,
    FISCAL_QUARTER,
    FISCAL_QUARTER_START,
    DATEADD(day, (WEEKS_IN_QUARTER * 7) - 1, FISCAL_QUARTER_START) AS FISCAL_QUARTER_END,
    WEEKS_IN_QUARTER,
    FISCAL_YEAR,
    FISCAL_YEAR_START,
    DATEADD(day, (WEEKS_IN_YEAR * 7) - 1, FISCAL_YEAR_START) AS FISCAL_YEAR_END,
    WEEKS_IN_YEAR
FROM CALC_BOUNDARIES
ORDER BY CALENDAR_DATE ASC;