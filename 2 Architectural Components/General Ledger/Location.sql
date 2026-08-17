USE DATABASE FIELD_SYSTEMS_EDW;
USE SCHEMA ARCHITECTURAL_COMPONENT;

USE ROLE FIELD_SYSTEMS_DEVELOPER_ROLE;
USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;



-- Create Dimension GL Location --
CREATE OR REPLACE TABLE FIELD_SYSTEMS_EDW.ARCHITECTURAL_COMPONENT.DIMENSION_GL_LOCATION (
    LOCATION        VARCHAR(50)   NOT NULL  COMMENT 'Location segment code',
    DESCRIPTION     VARCHAR(255)  NOT NULL  COMMENT 'Location description',
    ENABLED         VARCHAR(3)    NOT NULL  COMMENT 'Whether the segment value is enabled (Yes/No)',
    PARENT          VARCHAR(3)    NOT NULL  COMMENT 'Parent segment value',
    POSTING         VARCHAR(3)    NOT NULL  COMMENT 'Whether posting is allowed (Yes/No)',
    BUDGETING       VARCHAR(3)    NOT NULL  COMMENT 'Whether budgeting is allowed (Yes/No)',

    CONSTRAINT PK_DIMENSION_GL_LOCATION PRIMARY KEY (LOCATION)
)
COMMENT = 'GL segment dimension for locations sourced from Oracle EBS';
