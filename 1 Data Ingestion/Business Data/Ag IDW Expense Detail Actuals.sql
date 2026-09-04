-- AG IDW Expense Detail Actuals --


-- Setup --
USE ROLE FIELD_SYSTEMS_DEVELOPER_ROLE;

USE DATABASE FIELD_SYSTEMS_EDW;
USE SCHEMA BUSINESS_DATA;

USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;


-- Create AG_IDW_EXPENSE_DETAIL_ACTUALS view --
CREATE OR REPLACE VIEW FIELD_SYSTEMS_EDW.BUSINESS_DATA.AG_IDW_EXPENSE_DETAIL_ACTUALS AS
WITH deduplicated AS (
    SELECT DISTINCT
        "P&L Category",
        "GAAP Subsection",
        "GL Natural Account Description",
        "PL Natural Account Summary",
        "GAAP Subsection Description",
        "Cost Center",
        "Fiscal Period",
        "Amount USD"
    FROM FIELD_SYSTEMS_EDW.RAW_DATA.EBS_EXPENSE_DETAILS e
    WHERE e."Business Area Code" IN ('553')
)
SELECT
    "P&L Category",
    "GAAP Subsection",
    "GL Natural Account Description",
    "PL Natural Account Summary",
    CONCAT("GAAP Subsection Description", "PL Natural Account Summary") AS "Parent Level",
    "Cost Center",
    CONCAT("GAAP Subsection Description", "GL Natural Account Description") AS "Account Level",
    LEFT("Fiscal Period"::VARCHAR, 4) || '-M' || RIGHT("Fiscal Period"::VARCHAR, 2) AS "Fiscal Month",
    SUM("Amount USD") AS "Amount USD"
FROM deduplicated
GROUP BY
    "P&L Category",
    "GAAP Subsection",
    "GL Natural Account Description",
    "PL Natural Account Summary",
    "GAAP Subsection Description",
    "Cost Center",
    "Fiscal Period"
ORDER BY "Fiscal Month" DESC;
