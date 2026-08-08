-- AG IDW Expense Detail Actuals --


-- Setup --
USE ROLE FIELD_SYSTEMS_ADMIN_ROLE;

USE DATABASE FIELD_SYSTEMS_EDW;
USE SCHEMA BUSINESS_DATA;

USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;


-- Create AG_IDW_EXPENSE_DETAIL_ACTUALS view from EBS_EXPENSE_DETAILS --
CREATE OR REPLACE VIEW FIELD_SYSTEMS_EDW.BUSINESS_DATA.AG_IDW_EXPENSE_DETAIL_ACTUALS AS
SELECT
    "P&L Category",
    "GAAP Subsection",
    "GL Natural Account Description",
    "PL Natural Account Summary",
    CONCAT("GAAP Subsection Description", "PL Natural Account Summary") AS "Parent Level",
    "Cost Center",
    CONCAT("GAAP Subsection Description", "GL Natural Account Description") AS "Account Level",
    "Fiscal Period",
    SUM("Amount USD") AS "Amount USD"

FROM FIELD_SYSTEMS_EDW.RAW_DATA.EBS_EXPENSE_DETAILS
WHERE "Business Area Code" IN ('553')
  AND "Period Year" = YEAR(CURRENT_DATE())
GROUP BY
    "P&L Category",
    "GAAP Subsection",
    "GL Natural Account Description",
    "PL Natural Account Summary",
    "GAAP Subsection Description",
    "PL Natural Account Summary",
    "Cost Center",
    "GL Natural Account Description",
    "Fiscal Period"
ORDER BY "Fiscal Period" DESC;
