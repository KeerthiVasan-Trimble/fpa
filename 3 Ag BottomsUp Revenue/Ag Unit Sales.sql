-- Ag Unit Sales --


-- Setup --
USE ROLE FIELD_SYSTEMS_DEVELOPER_ROLE;

USE DATABASE FIELD_SYSTEMS_EDW;
USE SCHEMA GENERAL;

USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;


-- Create temporary table for simulting the one getting data from UI --
CREATE OR REPLACE TABLE DEV_AG_UNIT_SALES(RECEIVER_CODE VARCHAR(100)
                                         ,BILLINGS_MONTH VARCHAR(20)                                     
                                         ,UNITS_SOLD INTEGER);

INSERT INTO DEV_AG_UNIT_SALES (RECEIVER_CODE, BILLINGS_MONTH, UNITS_SOLD) VALUES
  ('AG-200',         '2026-07', 453),
  ('AG-392',         '2026-07', 215),
  ('AG-482',         '2026-07', 188),
  ('NAV-500',        '2026-07', 427),
  ('NAV-860',        '2026-07',  62),
  ('NAV-900',        '2026-07', 193),
  ('NAV-960',        '2026-07', 236),
  ('NAV-III',        '2026-07', 209),
  ('TERRIER AG-960', '2026-07', 366),
  ('Z - MSDA',       '2026-07', 267);
