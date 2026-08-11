-- =============================================================
-- OBSERVABILITY SCHEMA SETUP
-- Pre-aggregated cost data for fast querying
-- Restricted to FIELD_SYSTEMS_EDW database only
-- =============================================================


-- Prerequisites (requires ACCOUNTADMIN) --
USE ROLE ACCOUNTADMIN;
GRANT EXECUTE TASK ON ACCOUNT TO ROLE FIELD_SYSTEMS_ADMIN_ROLE;
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE TO ROLE FIELD_SYSTEMS_ADMIN_ROLE;


-- Switch to FIELD_SYSTEMS_ADMIN_ROLE for all remaining operations --
USE ROLE FIELD_SYSTEMS_ADMIN_ROLE;
USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;
USE DATABASE FIELD_SYSTEMS_EDW;


-- Schema Creation --
CREATE SCHEMA IF NOT EXISTS FIELD_SYSTEMS_EDW.OBSERVABILITY;


-- Table: Daily warehouse credits --
CREATE OR REPLACE TABLE FIELD_SYSTEMS_EDW.OBSERVABILITY.WAREHOUSE_CREDITS_DAILY (
    usage_date       DATE,
    warehouse_name   VARCHAR,
    total_credits    NUMBER(38, 4)
);


-- Table: Daily user execution --
CREATE OR REPLACE TABLE FIELD_SYSTEMS_EDW.OBSERVABILITY.USER_EXECUTION_DAILY (
    usage_date       DATE,
    role_name        VARCHAR,
    user_name        VARCHAR,
    warehouse_name   VARCHAR,
    user_exec_ms     NUMBER(38, 0),
    query_count      NUMBER(38, 0)
);


-- View: Apportioned cost per day/role/user/warehouse --
CREATE OR REPLACE VIEW FIELD_SYSTEMS_EDW.OBSERVABILITY.COST_APPORTIONED_DAILY AS
WITH warehouse_totals AS (
    SELECT
        usage_date,
        warehouse_name,
        SUM(user_exec_ms) AS total_exec_ms
    FROM FIELD_SYSTEMS_EDW.OBSERVABILITY.USER_EXECUTION_DAILY
    GROUP BY usage_date, warehouse_name
)
SELECT
    ue.usage_date,
    ue.user_name,
    ue.role_name,
    ue.warehouse_name,
    ue.query_count,
    ROUND(ue.user_exec_ms / 3600000, 4) AS execution_hours,
    ROUND(
        DIV0NULL(ue.user_exec_ms, wt.total_exec_ms) * wc.total_credits,
        4
    ) AS apportioned_credits
FROM FIELD_SYSTEMS_EDW.OBSERVABILITY.USER_EXECUTION_DAILY ue
JOIN warehouse_totals wt
    ON ue.usage_date = wt.usage_date AND ue.warehouse_name = wt.warehouse_name
LEFT JOIN FIELD_SYSTEMS_EDW.OBSERVABILITY.WAREHOUSE_CREDITS_DAILY wc
    ON ue.usage_date = wc.usage_date AND ue.warehouse_name = wc.warehouse_name
ORDER BY ue.usage_date DESC, ue.user_name ASC, ue.role_name ASC, ue.warehouse_name ASC;


-- Stored Procedure: Refresh cost data (last 90 days, FIELD_SYSTEMS_EDW only) --
CREATE OR REPLACE PROCEDURE FIELD_SYSTEMS_EDW.OBSERVABILITY.REFRESH_COST_DATA()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
BEGIN
    TRUNCATE TABLE FIELD_SYSTEMS_EDW.OBSERVABILITY.WAREHOUSE_CREDITS_DAILY;

    INSERT INTO FIELD_SYSTEMS_EDW.OBSERVABILITY.WAREHOUSE_CREDITS_DAILY
    SELECT
        TO_DATE(start_time) AS usage_date,
        warehouse_name,
        SUM(credits_used) AS total_credits
    FROM snowflake.account_usage.warehouse_metering_history
    WHERE start_time >= DATEADD('day', -90, CURRENT_TIMESTAMP())
      AND warehouse_name = 'FIELD_SYSTEMS_GENERAL_WAREHOUSE'
    GROUP BY usage_date, warehouse_name;

    TRUNCATE TABLE FIELD_SYSTEMS_EDW.OBSERVABILITY.USER_EXECUTION_DAILY;

    INSERT INTO FIELD_SYSTEMS_EDW.OBSERVABILITY.USER_EXECUTION_DAILY
    SELECT
        TO_DATE(start_time) AS usage_date,
        role_name,
        user_name,
        warehouse_name,
        SUM(execution_time) AS user_exec_ms,
        COUNT(*) AS query_count
    FROM snowflake.account_usage.query_history
    WHERE start_time >= DATEADD('day', -90, CURRENT_TIMESTAMP())
      AND warehouse_name IS NOT NULL
      AND database_name = 'FIELD_SYSTEMS_EDW'
    GROUP BY usage_date, role_name, user_name, warehouse_name;

    RETURN 'Cost data refreshed successfully';
END;


-- Task: Refresh every hour --
CREATE OR REPLACE TASK FIELD_SYSTEMS_EDW.OBSERVABILITY.REFRESH_COST_DATA_TASK
    WAREHOUSE = FIELD_SYSTEMS_GENERAL_WAREHOUSE
    SCHEDULE = 'USING CRON 0 0 * * * UTC'
AS
    CALL FIELD_SYSTEMS_EDW.OBSERVABILITY.REFRESH_COST_DATA();


-- Resume the task (tasks are created suspended by default) --
ALTER TASK FIELD_SYSTEMS_EDW.OBSERVABILITY.REFRESH_COST_DATA_TASK RESUME;


-- Initial data load --
CALL FIELD_SYSTEMS_EDW.OBSERVABILITY.REFRESH_COST_DATA();


-- Query the fast view --
SELECT * FROM FIELD_SYSTEMS_EDW.OBSERVABILITY.COST_APPORTIONED_DAILY;
