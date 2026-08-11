-- =============================================================
-- CORTEX CODE (CoCo) USAGE OBSERVABILITY
-- Tracks AI token consumption and costs per user
-- =============================================================


-- Prerequisites (requires ACCOUNTADMIN) --
USE ROLE ACCOUNTADMIN;
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE TO ROLE FIELD_SYSTEMS_ADMIN_ROLE;


-- Switch to FIELD_SYSTEMS_ADMIN_ROLE --
USE ROLE FIELD_SYSTEMS_ADMIN_ROLE;
USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;
USE DATABASE FIELD_SYSTEMS_EDW;


-- Ensure schema exists --
CREATE SCHEMA IF NOT EXISTS FIELD_SYSTEMS_EDW.OBSERVABILITY;


-- Table: Daily CoCo token consumption per user --
CREATE OR REPLACE TABLE FIELD_SYSTEMS_EDW.OBSERVABILITY.COCO_USAGE_DAILY (
    usage_date          DATE,
    user_name           VARCHAR,
    total_tokens        NUMBER,
    token_credits       NUMBER(38, 9),
    request_count       NUMBER
);


-- View: User-level AI consumption insights --
CREATE OR REPLACE VIEW FIELD_SYSTEMS_EDW.OBSERVABILITY.COCO_USAGE_INSIGHTS AS
SELECT
    usage_date,
    user_name,
    request_count,
    total_tokens,
    ROUND(total_tokens / NULLIF(request_count, 0), 0) AS avg_tokens_per_request,
    token_credits,
    SUM(token_credits) OVER (PARTITION BY user_name ORDER BY usage_date) AS running_total_credits,
    SUM(request_count) OVER (PARTITION BY user_name ORDER BY usage_date) AS running_total_requests
FROM FIELD_SYSTEMS_EDW.OBSERVABILITY.COCO_USAGE_DAILY
ORDER BY usage_date DESC, token_credits DESC;


-- View: Account-wide daily AI spend summary --
CREATE OR REPLACE VIEW FIELD_SYSTEMS_EDW.OBSERVABILITY.COCO_DAILY_SUMMARY AS
SELECT
    usage_date,
    user_name,
    SUM(request_count) AS total_requests,
    SUM(total_tokens) AS total_tokens,
    ROUND(SUM(total_tokens) / NULLIF(SUM(request_count), 0), 0) AS avg_tokens_per_request,
    SUM(token_credits) AS total_credits
FROM FIELD_SYSTEMS_EDW.OBSERVABILITY.COCO_USAGE_DAILY
GROUP BY usage_date, user_name
ORDER BY usage_date DESC, user_name ASC;


-- Stored Procedure: Refresh CoCo usage (last 90 days) --
CREATE OR REPLACE PROCEDURE FIELD_SYSTEMS_EDW.OBSERVABILITY.REFRESH_COCO_USAGE()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
BEGIN
    TRUNCATE TABLE FIELD_SYSTEMS_EDW.OBSERVABILITY.COCO_USAGE_DAILY;

    INSERT INTO FIELD_SYSTEMS_EDW.OBSERVABILITY.COCO_USAGE_DAILY
    SELECT
        TO_DATE(usage_time) AS usage_date,
        user_name,
        SUM(tokens) AS total_tokens,
        SUM(token_credits) AS token_credits,
        COUNT(*) AS request_count
    FROM snowflake.account_usage.cortex_code_snowsight_usage_history
    WHERE usage_time >= DATEADD('day', -90, CURRENT_TIMESTAMP())
    GROUP BY usage_date, user_name;

    RETURN 'CoCo usage data refreshed successfully';
END;


-- Task: Refresh every hour --
CREATE OR REPLACE TASK FIELD_SYSTEMS_EDW.OBSERVABILITY.REFRESH_COCO_USAGE_TASK
    WAREHOUSE = FIELD_SYSTEMS_GENERAL_WAREHOUSE
    SCHEDULE = 'USING CRON 0 0 * * * UTC'
AS
    CALL FIELD_SYSTEMS_EDW.OBSERVABILITY.REFRESH_COCO_USAGE();


-- Resume the task --
ALTER TASK FIELD_SYSTEMS_EDW.OBSERVABILITY.REFRESH_COCO_USAGE_TASK RESUME;



-- Initial data load --
CALL FIELD_SYSTEMS_EDW.OBSERVABILITY.REFRESH_COCO_USAGE();


-- Per-user AI consumption insights --
SELECT * FROM FIELD_SYSTEMS_EDW.OBSERVABILITY.COCO_USAGE_INSIGHTS;

-- Account-wide daily AI spend --
SELECT * FROM FIELD_SYSTEMS_EDW.OBSERVABILITY.COCO_DAILY_SUMMARY;
