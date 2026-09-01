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
    CREATE OR REPLACE VIEW FIELD_SYSTEMS_EDW.COMPUTATIONAL_COMPONENT.VIEW_AG_PCS_WATERFALL AS
    SELECT
        ''PCS Waterfall'' AS ROW_NAME,
        "' || full_yr || '-M01" AS "' || full_yr || '-01",
        "' || full_yr || '-M02" AS "' || full_yr || '-02",
        "' || full_yr || '-M03" AS "' || full_yr || '-03",
        "' || full_yr || '-M04" AS "' || full_yr || '-04",
        "' || full_yr || '-M05" AS "' || full_yr || '-05",
        "' || full_yr || '-M06" AS "' || full_yr || '-06",
        "' || full_yr || '-M07" AS "' || full_yr || '-07",
        "' || full_yr || '-M08" AS "' || full_yr || '-08",
        "' || full_yr || '-M09" AS "' || full_yr || '-09",
        "' || full_yr || '-M10" AS "' || full_yr || '-10",
        "' || full_yr || '-M11" AS "' || full_yr || '-11",
        "' || full_yr || '-M12" AS "' || full_yr || '-12"
    FROM FIELD_SYSTEMS_EDW.BUSINESS_DATA.PCS_CARVEOUT';

    EXECUTE IMMEDIATE sql_text;
END;
