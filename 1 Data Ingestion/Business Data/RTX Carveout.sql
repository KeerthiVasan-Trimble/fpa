-- RTX Carveout View --


-- Setup --
USE ROLE FIELD_SYSTEMS_DEVELOPER_ROLE;

USE DATABASE FIELD_SYSTEMS_EDW;
USE SCHEMA BUSINESS_DATA;

USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;


-- Create RTX Carveout view dynamically using current fiscal year --
DECLARE
    yr VARCHAR;
    full_yr VARCHAR;
    sql_text VARCHAR;
BEGIN
    SELECT RIGHT(FISCAL_YEAR::VARCHAR, 2) INTO :yr
    FROM FIELD_SYSTEMS_EDW.ARCHITECTURAL_COMPONENT.DIMENSION_FISCAL_CALENDAR
    WHERE CALENDAR_DATE = CURRENT_DATE();

    SELECT FISCAL_YEAR::VARCHAR INTO :full_yr
    FROM FIELD_SYSTEMS_EDW.ARCHITECTURAL_COMPONENT.DIMENSION_FISCAL_CALENDAR
    WHERE CALENDAR_DATE = CURRENT_DATE();

    sql_text := '
    CREATE OR REPLACE VIEW FIELD_SYSTEMS_EDW.BUSINESS_DATA.RTX_CARVEOUT AS
    WITH deduplicated AS (
        SELECT DISTINCT
            "Business Area Name",
            " Revenue Segments",
            "Jan_' || yr || '",
            "Feb_' || yr || '",
            "Mar_' || yr || '",
            "Apr_' || yr || '",
            "May_' || yr || '",
            "Jun_' || yr || '",
            "Jul_' || yr || '",
            "Aug_' || yr || '",
            "Sep_' || yr || '",
            "Oct_' || yr || '",
            "Nov_' || yr || '",
            "Dec_' || yr || '"
        FROM FIELD_SYSTEMS_EDW.RAW_DATA.REVPRO_WATERFALL
        WHERE " Revenue Segments" IN (''100.553.1000.40030.000.0000.00000'', ''380.553.1000.40030.000.0000.00000'')
          AND "Currency" IN (''Reporting'')
          AND "Data Element" IN (''Net Revenue - Actuals'')
          AND "GL Business Area Code" IN (''553'')
          AND " Sales Order Book Date" >= (SELECT MIN(FISCAL_YEAR_START) FROM FIELD_SYSTEMS_EDW.ARCHITECTURAL_COMPONENT.DIMENSION_FISCAL_CALENDAR WHERE FISCAL_YEAR = (SELECT FISCAL_YEAR FROM FIELD_SYSTEMS_EDW.ARCHITECTURAL_COMPONENT.DIMENSION_FISCAL_CALENDAR WHERE CALENDAR_DATE = CURRENT_DATE()))
    )
    SELECT
        "Business Area Name",
        " Revenue Segments",
        SUM("Jan_' || yr || '") AS "' || full_yr || '-M01",
        SUM("Feb_' || yr || '") AS "' || full_yr || '-M02",
        SUM("Mar_' || yr || '") AS "' || full_yr || '-M03",
        SUM("Apr_' || yr || '") AS "' || full_yr || '-M04",
        SUM("May_' || yr || '") AS "' || full_yr || '-M05",
        SUM("Jun_' || yr || '") AS "' || full_yr || '-M06",
        SUM("Jul_' || yr || '") AS "' || full_yr || '-M07",
        SUM("Aug_' || yr || '") AS "' || full_yr || '-M08",
        SUM("Sep_' || yr || '") AS "' || full_yr || '-M09",
        SUM("Oct_' || yr || '") AS "' || full_yr || '-M10",
        SUM("Nov_' || yr || '") AS "' || full_yr || '-M11",
        SUM("Dec_' || yr || '") AS "' || full_yr || '-M12"
    FROM deduplicated
    GROUP BY
        "Business Area Name",
        " Revenue Segments"';

    EXECUTE IMMEDIATE sql_text;
END;
