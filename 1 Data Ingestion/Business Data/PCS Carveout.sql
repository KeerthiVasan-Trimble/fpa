-- PCS Carveout View --


-- Setup --
USE ROLE FIELD_SYSTEMS_DEVELOPER_ROLE;

USE DATABASE FIELD_SYSTEMS_EDW;
USE SCHEMA BUSINESS_DATA;

USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;


-- Create PCS Carveout view dynamically using current fiscal year --
DECLARE
    yr VARCHAR;
    sql_text VARCHAR;
BEGIN
    SELECT RIGHT(FISCAL_YEAR::VARCHAR, 2) INTO :yr
    FROM FIELD_SYSTEMS_EDW.ARCHITECTURAL_COMPONENT.DIMENSION_FISCAL_CALENDAR
    WHERE CALENDAR_DATE = CURRENT_DATE();

    sql_text := '
    CREATE OR REPLACE VIEW FIELD_SYSTEMS_EDW.BUSINESS_DATA.PCS_CARVEOUT AS
    SELECT
        "GL Business Area Code",
        SUM("Jan_' || yr || '") AS "Jan_' || yr || '",
        SUM("Feb_' || yr || '") AS "Feb_' || yr || '",
        SUM("Mar_' || yr || '") AS "Mar_' || yr || '",
        SUM("Apr_' || yr || '") AS "Apr_' || yr || '",
        SUM("May_' || yr || '") AS "May_' || yr || '",
        SUM("Jun_' || yr || '") AS "Jun_' || yr || '",
        SUM("Jul_' || yr || '") AS "Jul_' || yr || '",
        SUM("Aug_' || yr || '") AS "Aug_' || yr || '",
        SUM("Sep_' || yr || '") AS "Sep_' || yr || '",
        SUM("Oct_' || yr || '") AS "Oct_' || yr || '",
        SUM("Nov_' || yr || '") AS "Nov_' || yr || '",
        SUM("Dec_' || yr || '") AS "Dec_' || yr || '"
    FROM FIELD_SYSTEMS_EDW.RAW_DATA.REVPRO_WATERFALL
    WHERE " Revenue Segments" IN (''100.553.1000.40012.000.0000.00000'', ''380.553.1000.40012.000.0000.00000'')
      AND "Currency" IN (''Reporting'')
      AND "Data Element" IN (''Net Revenue - Actuals'')
      AND "GL Business Area Code" IN (''553'')
    GROUP BY
        "GL Business Area Code"';

    EXECUTE IMMEDIATE sql_text;
END;
