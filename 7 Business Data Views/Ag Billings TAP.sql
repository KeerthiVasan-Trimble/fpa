-- Ag Bottoms Up Revenue Actuals --


-- Setup --
USE ROLE FIELD_SYSTEMS_ADMIN_ROLE;

USE DATABASE FIELD_SYSTEMS_EDW;
USE SCHEMA BUSINESS_DATA;

USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;


-- Create TAP view from ONE_AG --
CREATE OR REPLACE VIEW FIELD_SYSTEMS_EDW.BUSINESS_DATA.AG_BILLINGS_TAP AS
SELECT
    "Grouping",
    "item",
    "Item Description",
    "TAP Inclusion Type",
    "Invoice Date Period ID",
    SUM("Quantity Invoiced") AS "Quantity Invoiced",
    AVG("TAP Carveout") AS "TAP Carveout",
    SUM("Quantity Invoiced" * "TAP Carveout") AS "TAP Extended"

FROM FIELD_SYSTEMS_EDW.RAW_DATA.ONE_AG
WHERE "Sales Order" IS NULL
  AND "item" NOT IN ('108993-40', '108993-60', '108993-61', '108993-62', '108993-63', '108993-70', '108993-75', '108993-95')
  AND "name" IN ('PTx Trimble MSDA', 'PTx Trimble Supply Agreement')
  AND "Invoice Date Quarter ID" IN (YEAR(CURRENT_DATE()) || ' Q1', YEAR(CURRENT_DATE()) || ' Q2', YEAR(CURRENT_DATE()) || ' Q3', YEAR(CURRENT_DATE()) || ' Q4')
GROUP BY
    "Grouping",
    "item",
    "Item Description",
    "TAP Inclusion Type",
    "Invoice Date Period ID";


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

