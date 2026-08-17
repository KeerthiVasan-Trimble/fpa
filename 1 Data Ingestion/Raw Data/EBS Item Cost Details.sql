USE DATABASE FIELD_SYSTEMS_EDW;
USE SCHEMA RAW_DATA;

USE ROLE DOMO_INTEGRATION_ROLE;
USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;



-- Create EBS Item Cost Details --
-- Source: Oracle EBS via Domo integration (3.9M rows)
CREATE OR REPLACE TABLE FIELD_SYSTEMS_EDW.RAW_DATA.EBS_ITEM_COST_DETAILS (
    "Inventory Item ID" NUMBER(38,0),
    "Organization ID" NUMBER(38,0),
    "Item" VARCHAR(16777216),
    "Item Description" VARCHAR(16777216),
    "Business Area" VARCHAR(16777216),
    "Assembly Material Cost" FLOAT,
    "Component Material Cost" FLOAT,
    "Cost Type" VARCHAR(16777216),
    "Organization Code" VARCHAR(16777216),
    "Item Cost" FLOAT,
    "Item Schedule B" VARCHAR(16777216),
    "Item ECCN" VARCHAR(16777216),
    "Product Line" VARCHAR(16777216),
    "Product Group" VARCHAR(16777216),
    "Division" VARCHAR(16777216),
    "Cost Type Description" VARCHAR(16777216),
    "Material Cost" FLOAT,
    "Material Overhead Cost" FLOAT,
    "Resource Cost" FLOAT,
    "Outside Processing Cost" FLOAT,
    "Overhead Cost" FLOAT,
    "Component Material Overhead" FLOAT,
    "Component Resource Cost" FLOAT,
    "Component Outside Processing" FLOAT,
    "Component Overhead Cost" FLOAT,
    "Component Item Cost" FLOAT,
    "Assembly Material Overhead" FLOAT,
    "Assembly Resource Cost" FLOAT,
    "Assembly Outside Processing" FLOAT,
    "Assembly Overhead Cost" FLOAT,
    "Assembly Unit Cost" FLOAT,
    "Based On Rollup Flag" VARCHAR(16777216),
    "Shrinkage Rate" NUMBER(38,0),
    "Unburdened Cost" FLOAT,
    "Burden Cost" FLOAT,
    "Item CTCT Identifier" VARCHAR(16777216),
    "Inventory Item Status Code" VARCHAR(16777216),
    "Item Status" VARCHAR(16777216),
    "Customer Order Enabled Flag" VARCHAR(16777216),
    "Primary Unit Of Measure" VARCHAR(16777216),
    "Item Make or Buy Code" VARCHAR(16777216),
    "Item Type" VARCHAR(16777216),
    "CONVERT_TZ(`T3`.`Item Creation Date`, ''UTC'', ''America/Los_Angeles'')" TIMESTAMP_NTZ(9)
);
