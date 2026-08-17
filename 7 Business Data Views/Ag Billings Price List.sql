-- Ag Billings Price List with Groupings Model --


-- Setup --
USE ROLE FIELD_SYSTEMS_DEVELOPER_ROLE;

USE DATABASE FIELD_SYSTEMS_EDW;
USE SCHEMA BUSINESS_DATA;

USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;


-- Create Price List with Groupings Model view from ONE_AG joined to Fiscal Calendar --
CREATE OR REPLACE VIEW FIELD_SYSTEMS_EDW.BUSINESS_DATA.AG_BILLINGS_PRICE_LIST_WITH_GROUPINGS_MODEL AS
SELECT
    fc.FISCAL_MONTH_CODE AS "Fiscal Month",
    SUM("Quantity Invoiced") AS "Quantity Invoiced",
    "Grouping",
    "Product Line",
    "item",
    "Item Description",
    SUM("Extended Amount USD") AS "Extended Amount USD",
    AVG("Unit Selling Price USD") AS "Unit Selling Price USD",
    "Ag_Rolled Up Region",
    "Sales Order"

FROM FIELD_SYSTEMS_EDW.RAW_DATA.ONE_AG o
INNER JOIN FIELD_SYSTEMS_EDW.ARCHITECTURAL_COMPONENT.DIMENSION_FISCAL_CALENDAR fc
    ON o."GL Date" = fc.CALENDAR_DATE
WHERE fc.FISCAL_YEAR = (SELECT FISCAL_YEAR FROM FIELD_SYSTEMS_EDW.ARCHITECTURAL_COMPONENT.DIMENSION_FISCAL_CALENDAR WHERE CALENDAR_DATE = CURRENT_DATE())
GROUP BY
    fc.FISCAL_MONTH_CODE,
    "Grouping",
    "Product Line",
    "item",
    "Item Description",
    "Ag_Rolled Up Region",
    "Sales Order";
