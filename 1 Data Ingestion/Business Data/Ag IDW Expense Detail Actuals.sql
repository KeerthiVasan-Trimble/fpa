-- AG IDW Expense Detail Actuals --


-- Setup --
USE ROLE FIELD_SYSTEMS_DEVELOPER_ROLE;

USE DATABASE FIELD_SYSTEMS_EDW;
USE SCHEMA BUSINESS_DATA;

USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;


-- Create AG_IDW_EXPENSE_DETAIL_ACTUALS view joined to Fiscal Calendar --
CREATE OR REPLACE VIEW FIELD_SYSTEMS_EDW.BUSINESS_DATA.AG_IDW_EXPENSE_DETAIL_ACTUALS AS
WITH deduplicated AS (
    SELECT DISTINCT
        "P&L Category",
        "GAAP Subsection",
        "GL Natural Account Description",
        "PL Natural Account Summary",
        "GAAP Subsection Description",
        "Cost Center",
        fc.FISCAL_MONTH_CODE AS "Fiscal Month",
        "Amount USD"
    FROM FIELD_SYSTEMS_EDW.RAW_DATA.EBS_EXPENSE_DETAILS e
    INNER JOIN FIELD_SYSTEMS_EDW.ARCHITECTURAL_COMPONENT.DIMENSION_FISCAL_CALENDAR fc
        ON e."Accounting Date" = fc.CALENDAR_DATE
    WHERE e."Business Area Code" IN ('553')
      AND fc.FISCAL_YEAR = (SELECT FISCAL_YEAR FROM FIELD_SYSTEMS_EDW.ARCHITECTURAL_COMPONENT.DIMENSION_FISCAL_CALENDAR WHERE CALENDAR_DATE = CURRENT_DATE())
)
SELECT
    "P&L Category",
    "GAAP Subsection",
    "GL Natural Account Description",
    "PL Natural Account Summary",
    CONCAT("GAAP Subsection Description", "PL Natural Account Summary") AS "Parent Level",
    "Cost Center",
    CONCAT("GAAP Subsection Description", "GL Natural Account Description") AS "Account Level",
    "Fiscal Month",
    SUM("Amount USD") AS "Amount USD"
FROM deduplicated
GROUP BY
    "P&L Category",
    "GAAP Subsection",
    "GL Natural Account Description",
    "PL Natural Account Summary",
    "GAAP Subsection Description",
    "Cost Center",
    "Fiscal Month"
ORDER BY "Fiscal Month" DESC;
