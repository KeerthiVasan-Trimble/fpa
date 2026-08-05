-- Ag Bottoms Up Revenue Actuals --


-- Setup --
USE ROLE FIELD_SYSTEMS_DEVELOPER_ROLE;

USE DATABASE FIELD_SYSTEMS_EDW;
USE SCHEMA GENERAL;

USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;


-- Create dynamic table for Bottoms Up Revenue Calculation
CREATE OR REPLACE DYNAMIC TABLE DYNAMIC_AG_BOTTOMS_UP_REVENUE_ACTUALS
    TARGET_LAG = '24 hours'
    WAREHOUSE = 'FIELD_SYSTEMS_GENERAL_WAREHOUSE'
    AS
    SELECT "P&L Category"
           , "GAAP Subsection Description"
           , "GL Natural Account Description"
           , "PL Natural Account Summary"
           , "Cost Center"
           , concat("GAAP Subsection Description","PL Natural Account Summary") as "Parent Level"
           , "Business Area Code"
           , concat("GAAP Subsection Description","GL Natural Account Description") as "Account Level"
           , "Fiscal Period"
           , sum("Amount USD") AS "Total Amount USD"
    FROM RAW_DATA_EBS_EXPENSE_DETAILS 
    WHERE "Business Area Code" = 553
          AND "Period Year" = 2026
          AND "Quarter ID" in ('2026 Q1', '2026 Q2')
          AND "Fiscal Period" in ('202601', '202602', '202603', '202604', '202605', '202606', '202607')
    GROUP BY "P&L Category"
           , "GAAP Subsection Description"
           , "GL Natural Account Description"
           , "PL Natural Account Summary"
           , "Cost Center"
           , concat("GAAP Subsection Description","PL Natural Account Summary")
           , "Business Area Code"
           , concat("GAAP Subsection Description","GL Natural Account Description")
           , "Fiscal Period"
    ORDER BY "P&L Category" ASC
           , "GAAP Subsection Description" ASC
           , "GL Natural Account Description" ASC
           , "PL Natural Account Summary" ASC
           , "Cost Center" ASC
           , concat("GAAP Subsection Description","PL Natural Account Summary") ASC
           , "Business Area Code" ASC
           , concat("GAAP Subsection Description","GL Natural Account Description") ASC
           , "Fiscal Period" ASC;

-- Select * from DYNAMIC_AG_BOTTOMS_UP_REVENUE_ACTUALS limit 10;