-- Ag Billings Price List with Groupings Model --


-- Setup --
USE ROLE FIELD_SYSTEMS_DEVELOPER_ROLE;

USE DATABASE FIELD_SYSTEMS_EDW;
USE SCHEMA BUSINESS_DATA;

USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;


-- Create Price List with Groupings Model view from ONE_AG --
CREATE OR REPLACE VIEW FIELD_SYSTEMS_EDW.BUSINESS_DATA.AG_BILLINGS_PRICE_LIST_WITH_GROUPINGS_MODEL AS
WITH deduplicated AS (
    SELECT DISTINCT
        "GL Date" AS "Fiscal Month",
        "Quantity Invoiced",
        "Grouping",
        "Product Line",
        "item",
        "Item Description",
        "Extended Amount USD",
        "Unit Selling Price USD",
        "Ag_Rolled Up Region",
        "Sales Order"
    FROM FIELD_SYSTEMS_EDW.RAW_DATA.ONE_AG
    WHERE YEAR("GL Date") = YEAR(CURRENT_DATE())
)
SELECT
    "Fiscal Month",
    SUM("Quantity Invoiced") AS "Quantity Invoiced",
    "Grouping",
    "Product Line",
    "item",
    "Item Description",
    SUM("Extended Amount USD") AS "Extended Amount USD",
    AVG("Unit Selling Price USD") AS "Unit Selling Price USD",
    "Ag_Rolled Up Region",
    "Sales Order"
FROM deduplicated
GROUP BY
    "Fiscal Month",
    "Grouping",
    "Product Line",
    "item",
    "Item Description",
    "Ag_Rolled Up Region",
    "Sales Order";
