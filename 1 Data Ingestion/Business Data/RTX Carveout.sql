-- RTX Carveout View --


-- Setup --
USE ROLE FIELD_SYSTEMS_DEVELOPER_ROLE;

USE DATABASE FIELD_SYSTEMS_EDW;
USE SCHEMA BUSINESS_DATA;

USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;


-- Create RTX Carveout view dynamically using current calendar year --
DECLARE
    yr VARCHAR;
    full_yr VARCHAR;
    sql_text VARCHAR;
BEGIN
    SELECT RIGHT(YEAR(CURRENT_DATE())::VARCHAR, 2) INTO :yr;

    SELECT YEAR(CURRENT_DATE())::VARCHAR INTO :full_yr;

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
          AND YEAR(" Sales Order Book Date") >= YEAR(CURRENT_DATE())
    )
    SELECT
        "Business Area Name",
        " Revenue Segments",
        SUM("Jan_' || yr || '") AS "' || full_yr || '-01",
        SUM("Feb_' || yr || '") AS "' || full_yr || '-02",
        SUM("Mar_' || yr || '") AS "' || full_yr || '-03",
        SUM("Apr_' || yr || '") AS "' || full_yr || '-04",
        SUM("May_' || yr || '") AS "' || full_yr || '-05",
        SUM("Jun_' || yr || '") AS "' || full_yr || '-06",
        SUM("Jul_' || yr || '") AS "' || full_yr || '-07",
        SUM("Aug_' || yr || '") AS "' || full_yr || '-08",
        SUM("Sep_' || yr || '") AS "' || full_yr || '-09",
        SUM("Oct_' || yr || '") AS "' || full_yr || '-10",
        SUM("Nov_' || yr || '") AS "' || full_yr || '-11",
        SUM("Dec_' || yr || '") AS "' || full_yr || '-12"
    FROM deduplicated
    GROUP BY
        "Business Area Name",
        " Revenue Segments"';

    EXECUTE IMMEDIATE sql_text;
END;
