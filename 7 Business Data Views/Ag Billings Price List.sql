-- Ag Billings Price List with Groupings Model --


-- Setup --
USE ROLE FIELD_SYSTEMS_ADMIN_ROLE;

USE DATABASE FIELD_SYSTEMS_EDW;
USE SCHEMA BUSINESS_DATA;

USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;


-- Create Price List with Groupings Model view from ONE_AG --
CREATE OR REPLACE VIEW FIELD_SYSTEMS_EDW.BUSINESS_DATA.AG_BILLINGS_PRICE_LIST_WITH_GROUPINGS_MODEL AS
SELECT
    "GL Date Period ID",
    SUM("Quantity Invoiced") AS "Quantity Invoiced",
    "Grouping",
    "Product Line",
    "item",
    "Item Description",
    SUM("Extended Amount USD") AS "Extended Amount USD",
    AVG("Unit Selling Price USD") AS "Unit Selling Price USD",
    "Ag_Rolled Up Region",
    "Sales Order"

FROM FIELD_SYSTEMS_EDW.RAW_DATA.ONE_AG
WHERE "GL Date Quarter ID" IN (YEAR(CURRENT_DATE()) || ' Q1', YEAR(CURRENT_DATE()) || ' Q2', YEAR(CURRENT_DATE()) || ' Q3', YEAR(CURRENT_DATE()) || ' Q4')
GROUP BY
    "GL Date Period ID",
    "Grouping",
    "Product Line",
    "item",
    "Item Description",
    "Ag_Rolled Up Region",
    "Sales Order";


select * from FIELD_SYSTEMS_EDW.BUSINESS_DATA.AG_BILLINGS_PRICE_LIST_WITH_GROUPINGS_MODEL;