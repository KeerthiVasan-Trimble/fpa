-- Ag Frozen Cost ARF View --


-- Setup --
USE ROLE FIELD_SYSTEMS_DEVELOPER_ROLE;

USE DATABASE FIELD_SYSTEMS_EDW;
USE SCHEMA BUSINESS_DATA;

USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;


-- Create Ag Frozen Cost ARF view --
CREATE OR REPLACE VIEW FIELD_SYSTEMS_EDW.BUSINESS_DATA.AG_FROZEN_COST_ARF AS
SELECT DISTINCT
    "Item",
    "Item Description",
    "Item Status",
    "Inventory Item Status Code",
    "Assembly Material Overhead",
    "Assembly Outside Processing",
    "Assembly Overhead Cost",
    "Assembly Resource Cost",
    "Assembly Unit Cost",
    "Component Item Cost",
    "Component Material Cost",
    "Component Material Overhead",
    "Component Outside Processing",
    "Component Overhead Cost",
    "Component Resource Cost",
    "Cost Type",
    "Item Cost",
    "Material Cost",
    "Material Overhead Cost",
    "Outside Processing Cost",
    "Overhead Cost",
    "Resource Cost",
    "Shrinkage Rate",
    "Primary Unit Of Measure",
    "Business Area",
    "Product Group",
    "Product Line",
    "Customer Order Enabled Flag"

FROM FIELD_SYSTEMS_EDW.RAW_DATA.EBS_ITEM_COST_DETAILS
WHERE "Cost Type" = 'Frozen'
  AND "Organization Code" = 'ARF'
  AND "Inventory Item Status Code" IN ('Active', 'CEM Active', 'MFG Active', 'NLS Active', 'Obsolete', 'Pending', 'Prototype', 'Replaced')
  AND "Business Area" IN (
      'AG SERVICES',
      'AGIS',
      'AUTO-IVN',
      'BUILDING CONSTRUCTION',
      'CORP,MANUFACTURING',
      'FORENSICS',
      'FORESTRY AUTOMATION',
      'GC PROJECT SOFTWARE',
      'GEO3D',
      'HEAVY & HIGHWAY',
      'HEAVY & HIGHWAY - CTCT',
      'HEAVY CIVIL - SPS',
      'ICT LLC',
      'INBOUND ON-ROAD',
      'MUELLER CORE',
      'MUELLER INC',
      'SMART MACHINES',
      'SP/NIKON',
      'TRIMBLE POSITIONING SERVICES',
      'UTILITIES FSM',
      'VICO SOFTWARE',
      'WATER SOLUTIONS'
  );
