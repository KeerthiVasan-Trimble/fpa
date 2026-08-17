USE DATABASE FIELD_SYSTEMS_EDW;
USE SCHEMA ARCHITECTURAL_COMPONENT;

USE ROLE FIELD_SYSTEMS_DEVELOPER_ROLE;
USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;



-- Create Dimension GL Cost Center --
CREATE OR REPLACE TABLE FIELD_SYSTEMS_EDW.ARCHITECTURAL_COMPONENT.DIMENSION_GL_COST_CENTER (
    COST_CENTER     VARCHAR(50)   NOT NULL  COMMENT 'Cost center segment code',
    DESCRIPTION     VARCHAR(255)  NOT NULL  COMMENT 'Cost center description',
    ENABLED         VARCHAR(3)    NOT NULL  COMMENT 'Whether the segment value is enabled (Yes/No)',
    PARENT          VARCHAR(3)    NOT NULL  COMMENT 'Parent segment value',
    POSTING         VARCHAR(3)    NOT NULL  COMMENT 'Whether posting is allowed (Yes/No)',
    BUDGETING       VARCHAR(3)    NOT NULL  COMMENT 'Whether budgeting is allowed (Yes/No)',

    CONSTRAINT PK_DIMENSION_GL_COST_CENTER PRIMARY KEY (COST_CENTER)
)
COMMENT = 'GL segment dimension for cost centers sourced from Oracle EBS';
