USE DATABASE FIELD_SYSTEMS_EDW;
USE SCHEMA ARCHITECTURAL_COMPONENT;

USE ROLE FIELD_SYSTEMS_DEVELOPER_ROLE;
USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;



-- Create Dimension GL Natural Account --
CREATE OR REPLACE TABLE FIELD_SYSTEMS_EDW.ARCHITECTURAL_COMPONENT.DIMENSION_GL_NATURAL_ACCOUNT (
    NATURAL_ACCOUNT VARCHAR(50)   NOT NULL  COMMENT 'Natural account segment code',
    DESCRIPTION     VARCHAR(255)  NOT NULL  COMMENT 'Natural account description',
    ENABLED         VARCHAR(3)    NOT NULL  COMMENT 'Whether the segment value is enabled (Yes/No)',
    PARENT          VARCHAR(3)    NOT NULL  COMMENT 'Parent segment value',
    POSTING         VARCHAR(3)    NOT NULL  COMMENT 'Whether posting is allowed (Yes/No)',
    BUDGETING       VARCHAR(3)    NOT NULL  COMMENT 'Whether budgeting is allowed (Yes/No)',
    ACCOUNT_TYPE    VARCHAR(50)   NOT NULL  COMMENT 'Account type classification (Asset, Liability, Revenue, Expense, etc.)',

    CONSTRAINT PK_DIMENSION_GL_NATURAL_ACCOUNT PRIMARY KEY (NATURAL_ACCOUNT)
)
COMMENT = 'GL segment dimension for natural accounts sourced from Oracle EBS';
