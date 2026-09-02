-- Ag Billings TAP --


-- Setup --
USE ROLE FIELD_SYSTEMS_DEVELOPER_ROLE;

USE DATABASE FIELD_SYSTEMS_EDW;
USE SCHEMA BUSINESS_DATA;

USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;


-- Create TAP view from ONE_AG --
CREATE OR REPLACE VIEW FIELD_SYSTEMS_EDW.BUSINESS_DATA.AG_BILLINGS_TAP AS
WITH deduplicated AS (
    SELECT DISTINCT
        "Grouping",
        "item",
        "Item Description",
        "TAP Inclusion Type",
        "Invoice Transaction Date" AS "Fiscal Month",
        "Quantity Invoiced",
        "TAP Carveout"
    FROM FIELD_SYSTEMS_EDW.RAW_DATA.ONE_AG
    WHERE "Sales Order" IS NULL
      AND "item" NOT IN ('108993-40', '108993-60', '108993-61', '108993-62', '108993-63', '108993-70', '108993-75', '108993-95')
      AND "name" IN ('PTx Trimble MSDA', 'PTx Trimble Supply Agreement')
      AND YEAR("Invoice Transaction Date") = YEAR(CURRENT_DATE())
)
SELECT
    "Grouping",
    "item",
    "Item Description",
    "TAP Inclusion Type",
    "Fiscal Month",
    SUM("Quantity Invoiced") AS "Quantity Invoiced",
    AVG("TAP Carveout") AS "TAP Carveout",
    SUM("Quantity Invoiced" * "TAP Carveout") AS "TAP Extended"
FROM deduplicated
GROUP BY
    "Grouping",
    "item",
    "Item Description",
    "TAP Inclusion Type",
    "Fiscal Month";
