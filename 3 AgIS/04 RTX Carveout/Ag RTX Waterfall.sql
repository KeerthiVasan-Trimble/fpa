USE ROLE FIELD_SYSTEMS_DEVELOPER_ROLE;

USE DATABASE FIELD_SYSTEMS_EDW;
USE SCHEMA COMPUTATIONAL_COMPONENT;

USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;

DECLARE
    full_yr VARCHAR;
    sql_text VARCHAR;
BEGIN
    SELECT FISCAL_YEAR::VARCHAR INTO :full_yr
    FROM FIELD_SYSTEMS_EDW.ARCHITECTURAL_COMPONENT.DIMENSION_FISCAL_CALENDAR
    WHERE CALENDAR_DATE = CURRENT_DATE();

    sql_text := '
    CREATE OR REPLACE VIEW FIELD_SYSTEMS_EDW.COMPUTATIONAL_COMPONENT.VIEW_AG_RTX_WATERFALL AS
    SELECT
        ''RTX Waterfall'' AS ROW_NAME,
        SUM("' || full_yr || '-M01") AS "' || full_yr || '-01",
        SUM("' || full_yr || '-M02") AS "' || full_yr || '-02",
        SUM("' || full_yr || '-M03") AS "' || full_yr || '-03",
        SUM("' || full_yr || '-M04") AS "' || full_yr || '-04",
        SUM("' || full_yr || '-M05") AS "' || full_yr || '-05",
        SUM("' || full_yr || '-M06") AS "' || full_yr || '-06",
        SUM("' || full_yr || '-M07") AS "' || full_yr || '-07",
        SUM("' || full_yr || '-M08") AS "' || full_yr || '-08",
        SUM("' || full_yr || '-M09") AS "' || full_yr || '-09",
        SUM("' || full_yr || '-M10") AS "' || full_yr || '-10",
        SUM("' || full_yr || '-M11") AS "' || full_yr || '-11",
        SUM("' || full_yr || '-M12") AS "' || full_yr || '-12"
    FROM FIELD_SYSTEMS_EDW.BUSINESS_DATA.RTX_CARVEOUT
    GROUP BY ROW_NAME';

    EXECUTE IMMEDIATE sql_text;
END;
