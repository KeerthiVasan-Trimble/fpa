-- Ag Unit Price --

-- Setup --
USE ROLE FIELD_SYSTEMS_DEVELOPER_ROLE;

USE DATABASE FIELD_SYSTEMS_EDW;
USE SCHEMA GENERAL;

USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;


-- Create a dynamic table for Price List --
CREATE OR REPLACE DYNAMIC TABLE DYNAMIC_AG_BILLINGS_PRICE_LIST
    TARGET_LAG = '24 hours'
    WAREHOUSE = 'FIELD_SYSTEMS_GENERAL_WAREHOUSE'
    AS
    SELECT "item"
           ,"Item Description"
           ,sum("Quantity Invoiced") as "Total Quantity Invoiced"
           ,sum("Extended Amount USD") as "Total Extended Amount"
           ,avg("Unit Selling Price USD") as "Unit Selling Price USD"
    FROM FIELD_SYSTEMS_EDW.GENERAL.RAW_DATA_ONE_AG
    WHERE "GL Date Quarter ID" = '2026 Q2' 
    AND "name" in ('PTx Trimble MSDA', 'PTx Trimble Supply Agreement')
    GROUP BY "item", "Item Description";


-- Create a dynamic table for select receivers --
CREATE OR REPLACE DYNAMIC TABLE DYNAMIC_AG_UNIT_PRICE_TABLE
    TARGET_LAG = '24 hours'
    WAREHOUSE = 'FIELD_SYSTEMS_GENERAL_WAREHOUSE'
    AS
    SELECT "item"
           , "Item Description"
           , REGEXP_SUBSTR("Item Description", 
                           'Ag-392|Ag-482|Nav-500|Nav-900|Nav-III|Z - MSDA|Nav-960|Nav-860|Ag-200|Terrier AG-960', 
                           1, 1, 'i') AS RECEIVER_CODE
           , "Total Quantity Invoiced"
           , "Total Extended Amount"
           , "Unit Selling Price USD"
    FROM DYNAMIC_AG_BILLINGS_PRICE_LIST
    WHERE RECEIVER_CODE IS NOT NULL;

-- select * from DYNAMIC_AG_UNIT_PRICE_TABLE;
