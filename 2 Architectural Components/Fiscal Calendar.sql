-- Fiscal Calendar --


-- Setup --
USE ROLE FIELD_SYSTEMS_DEVELOPER_ROLE;

USE DATABASE FIELD_SYSTEMS_EDW;
USE SCHEMA GENERAL;

USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;


-- Stage for Calendar CSV files --
CREATE STAGE IF NOT EXISTS FIELD_SYSTEMS_EDW.GENERAL.FISCAL_CALENDAR_STAGE;


-- Create Dimension Fiscal Calendar --
CREATE OR REPLACE TABLE FIELD_SYSTEMS_EDW.GENERAL.DIMENSION_FISCAL_CALENDAR (DATE_KEY              NUMBER(10),
                                                                             CALENDAR_DATE         DATE,
                                                                             DAY_OF_WEEK           NUMBER(1),
                                                                             FISCAL_WEEK_CODE      VARCHAR(10),
                                                                             FISCAL_WEEK           NUMBER(2),
                                                                             FISCAL_WEEK_START     DATE,
                                                                             FISCAL_WEEK_END       DATE,
                                                                             FISCAL_MONTH_CODE     VARCHAR(10),
                                                                             FISCAL_MONTH          NUMBER(2),
                                                                             FISCAL_MONTH_START    DATE,
                                                                             FISCAL_MONTH_END      DATE,
                                                                             WEEKS_IN_MONTH        NUMBER(2),
                                                                             FISCAL_QUARTER_CODE   VARCHAR(10),
                                                                             FISCAL_QUARTER        NUMBER(1),
                                                                             FISCAL_QUARTER_START  DATE,
                                                                             FISCAL_QUARTER_END    DATE,
                                                                             WEEKS_IN_QUARTER      NUMBER(1),
                                                                             FISCAL_YEAR           NUMBER(4),
                                                                             FISCAL_YEAR_START     DATE,
                                                                             FISCAL_YEAR_END       DATE,
                                                                             WEEKS_IN_YEAR         NUMBER(2));


--  select * from DIMENSION_FISCAL_CALENDAR limit 10;
