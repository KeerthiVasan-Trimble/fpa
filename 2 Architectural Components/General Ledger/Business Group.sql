USE DATABASE FIELD_SYSTEMS_EDW;
USE SCHEMA ARCHITECTURAL_COMPONENT;

USE ROLE FIELD_SYSTEMS_DEVELOPER_ROLE;
USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;



-- Create Dimension GL Business Group --
CREATE OR REPLACE TABLE FIELD_SYSTEMS_EDW.ARCHITECTURAL_COMPONENT.DIMENSION_GL_BUSINESS_GROUP (
    BUSINESS_AREA   VARCHAR(10)   NOT NULL  COMMENT 'Business area segment code',
    DESCRIPTION     VARCHAR(255)  NOT NULL  COMMENT 'Business area description',
    ENABLED         VARCHAR(3)    NOT NULL  COMMENT 'Whether the segment value is enabled (Yes/No)',
    PARENT          VARCHAR(10)   NOT NULL  COMMENT 'Parent segment value',
    POSTING         VARCHAR(3)    NOT NULL  COMMENT 'Whether posting is allowed (Yes/No)',
    BUDGETING       VARCHAR(3)    NOT NULL  COMMENT 'Whether budgeting is allowed (Yes/No)',

    CONSTRAINT PK_DIMENSION_GL_BUSINESS_GROUP PRIMARY KEY (BUSINESS_AREA)
)
COMMENT = 'GL segment dimension for business area groupings sourced from Oracle EBS';
