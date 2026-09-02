-- Field Systems Adaptive Upload View --


-- Setup --
USE ROLE FIELD_SYSTEMS_DEVELOPER_ROLE;

USE DATABASE FIELD_SYSTEMS_EDW;
USE SCHEMA BUSINESS_DATA;

USE WAREHOUSE FIELD_SYSTEMS_GENERAL_WAREHOUSE;


-- Create Field Systems Adaptive Upload view --
CREATE OR REPLACE VIEW FIELD_SYSTEMS_EDW.BUSINESS_DATA.FIELD_SYSTEMS_ADAPTIVE_UPLOAD AS
WITH deduplicated AS (
    SELECT DISTINCT
        "Natural Account Code",
        "Business Area Code",
        "Base Currency Code",
        "Cost Center Code",
        "Cost Center",
        "Reporting Entity Code",
        "Reporting Entity",
        "P&L Category",
        "Amount Func Currency",
        "GAAP Subsection",
        "GL Divisional Group Description",
        "GL Division Description",
        "GAAP Subsection Description",
        "Amount USD"
    FROM FIELD_SYSTEMS_EDW.RAW_DATA.EBS_EXPENSE_DETAILS e
    INNER JOIN FIELD_SYSTEMS_EDW.ARCHITECTURAL_COMPONENT.DIMENSION_FISCAL_CALENDAR fc
        ON e."Accounting Date" = fc.CALENDAR_DATE
    WHERE e."Cost Center Code" = '1000'
      AND fc.FISCAL_YEAR >= 2020
      AND e."GL Divisional Group Description" = '980:FIELD SYSTEMS'
      AND e."Natural Account Code" NOT IN ('70129', '73710', '73711', '604100', '605100', '606300')
      AND e."SOB Grouping" NOT IN ('LOCALSTAT')
)
SELECT
    CONCAT('CAPL.', "Natural Account Code") AS "Income Statement Account",
    CONCAT("Business Area Code", '-', CASE WHEN "Base Currency Code" = 'KPW' THEN 'KRW' ELSE "Base Currency Code" END) AS "Adaptive Level",
    "Cost Center Code",
    "Cost Center",
    "Reporting Entity Code",
    "Reporting Entity",
    SUM(CASE WHEN "P&L Category" = '1.REVENUE' THEN -"Amount Func Currency" ELSE "Amount Func Currency" END) AS "RevRev Func Currency",
    CASE
        WHEN "GAAP Subsection" = 'Revenue' THEN '1:Revenue'
        WHEN "GAAP Subsection" = 'R&D' THEN '3:R&D'
        WHEN "GAAP Subsection" = 'Marketing' THEN '4:Marketing'
        WHEN "GAAP Subsection" = 'Sales' THEN '5:Sales'
        WHEN "GAAP Subsection" = 'G&A' THEN '6:G&A'
        WHEN "GAAP Subsection" = 'Non Operating Exp (Inc)' THEN '7:Non-Operating'
        ELSE '2:COGS'
    END AS "CES Subsection",
    "Business Area Code",
    "GL Divisional Group Description",
    "GL Division Description",
    "GAAP Subsection Description",
    SUM("Amount USD") AS "Amount USD",
    CASE
        WHEN "Business Area Code" = '112' THEN 'Y' -- CCFS - On Machine - 112:HEAVY & HIGHWAY - CTCT
        WHEN "Business Area Code" = '113' THEN 'Y' -- CCFS - On Machine - 113:HEAVY & HIGHWAY
        WHEN "Business Area Code" = '123' THEN 'Y' -- CCFS - On Machine - 123:CTCT IMPACT
        WHEN "Business Area Code" = '157' THEN 'Y' -- CCFS - On Machine - 157:HEAVY CIVIL - OEM
        WHEN "Business Area Code" = '504' THEN 'Y' -- CCFS - On Machine - 504:AUTONOMOUS SOLUTIONS
        WHEN "Business Area Code" = '156' THEN 'Y' -- CCFS - 156:HEAVY CIVIL - SPS
        WHEN "Business Area Code" = '118' THEN 'Y' -- CCFS - DSM - 118:CONSTRUCTION SERVICES
        WHEN "Business Area Code" = '203' THEN 'Y' -- CCFS - DSM - 203:CEC SOFTWARE BUSINESS
        WHEN "Business Area Code" = '104' THEN 'Y' -- CCFS - Lifting - 104:TPAC - LIFTING SOLUTIONS
        WHEN "Business Area Code" = '169' THEN 'Y' -- CCFS - Lifting - 169:LOAD SYSTEMS
        WHEN "Business Area Code" = '127' THEN 'Y' -- CCFS - CCFS Other - 127:CONSTRUCTION PLANNING
        WHEN "Business Area Code" = '128' THEN 'Y' -- CCFS - CCFS Other - 128:HEAVY CIVIL - TECH CONSULTING SERVICES
        WHEN "Business Area Code" = '141' THEN 'Y' -- CCFS - CCFS Other - 141:CONSTRUCTION REFURBISHED PRODUCTS
        WHEN "Business Area Code" = '142' THEN 'Y' -- CCFS - CCFS Other - 142:GLOBAL SERVICES TRAINING
        WHEN "Business Area Code" = '223' THEN 'Y' -- CCFS - CCFS Other - 223:CONTRACTOR APPS
        WHEN "Business Area Code" = '224' THEN 'Y' -- CCFS - CCFS Other - 224:SITEVISION
        WHEN "Business Area Code" = '233' THEN 'Y' -- CCFS - CCFS Other - 233:STRATEGIC ACCOUNT MANAGEMENT
        WHEN "Business Area Code" = '553' THEN 'Y' -- CCFS - AGIS - 553:AgIS
        WHEN "Business Area Code" = '114' THEN 'Y' -- Geo-BCFS - 114:Building Construction
        WHEN "Business Area Code" = '117' THEN 'Y' -- Geo-BCFS - 117:MIXED REALITY FTG
        WHEN "Business Area Code" = '137' THEN 'Y' -- Geo-BCFS - 137:HILTI IMPACT
        WHEN "Business Area Code" = '136' THEN 'Y' -- Geo-BCFS - 136:ICT LLC
        WHEN "Business Area Code" = '238' THEN 'Y' -- Geo-BCFS - 238:ROBOTICS FTG
        WHEN "Business Area Code" = '180' THEN 'Y' -- Geo-Land Admin - 180:CADASTRAL
        WHEN "Business Area Code" = '208' THEN 'Y' -- Geo-Land Admin - 208:PENMAP
        WHEN "Business Area Code" = '107' THEN 'Y' -- Geo-Core - 107:POWER PROCESS & PLANT
        WHEN "Business Area Code" = '186' THEN 'Y' -- Geo-Core - 186:OPTICAL & IMAGING
        WHEN "Business Area Code" = '187' THEN 'Y' -- Geo-Core - 187:GNSS
        WHEN "Business Area Code" = '194' THEN 'Y' -- Geo-Core - 194:SOFT GNSS
        WHEN "Business Area Code" = '108' THEN 'Y' -- Geo-Core - 108:SP/NIKON
        WHEN "Business Area Code" = '179' THEN 'Y' -- Geo-Core - 179:INTERNAL PACCREST RADIOS
        WHEN "Business Area Code" = '602' THEN 'Y' -- Geo-Core - 602:GEO3D
        WHEN "Business Area Code" = '603' THEN 'Y' -- Geo-Core - 603:AIRBORNE SYSTEMS
        WHEN "Business Area Code" = '500' THEN 'Y' -- Geo-Core - 500:TFS - GIS
        WHEN "Business Area Code" = '188' THEN 'Y' -- Geo-Core - 188:SURVEY SOLUTIONS
        WHEN "Business Area Code" = '600' THEN 'Y' -- Geo-Core - 600:INPHO
        WHEN "Business Area Code" = '606' THEN 'Y' -- Geo-Core - 606:eCognition
        WHEN "Business Area Code" = '292' THEN 'Y' -- Geo-Core - 292:GEO IDR ELIM
        WHEN "Business Area Code" = '132' THEN 'Y' -- Geo-Core - 132:MOBILE COMPUTING
        WHEN "Business Area Code" = '176' THEN 'Y' -- Geo-Core - 176:FORENSICS
        WHEN "Business Area Code" = '181' THEN 'Y' -- Geo-Core - 181:RAIL
        WHEN "Business Area Code" = '111' THEN 'Y' -- Geo-Core - 111:SURVEY
        WHEN "Business Area Code" = '149' THEN 'Y' -- Geo-Core - 149:MONITORING
        WHEN "Business Area Code" = '150' THEN 'Y' -- Geo-Core - 150:INTELLIGENT SENSORS & SCANNING
        WHEN "Business Area Code" = '162' THEN 'Y' -- Geo-Core - 162:TIS HUNGARY
        WHEN "Business Area Code" = '115' THEN 'Y' -- Geo-Core - 115:3D SCANNING SOLUTIONS
        WHEN "Business Area Code" = '131' THEN 'Y' -- Geo-Core - 131:ASHTECH
        WHEN "Business Area Code" = '182' THEN 'Y' -- Geo-Core - 182:SEISMIC SURVEY
        WHEN "Business Area Code" = '183' THEN 'Y' -- Geo-Core - 183:GATEWING
        WHEN "Business Area Code" = '316' THEN 'Y' -- Geo-Core - 316:TIMING
        WHEN "Business Area Code" = '601' THEN 'Y' -- Geo-Core - 601:GEOSPATIAL ADMIN
        WHEN "Business Area Code" = '690' THEN 'Y' -- Geo-Core - 690:GEOSPATIAL SECTOR SALES
        WHEN "Business Area Code" = '139' THEN 'Y' -- Geo-Core - 139:GLOBAL SERVICES TECHNICAL SUPPORT
        WHEN "Business Area Code" = '235' THEN 'Y' -- Advanced Positioning - 235:CORE APPLANIX
        WHEN "Business Area Code" = '237' THEN 'Y' -- Advanced Positioning - 237:INBOUND OFF-ROAD
        WHEN "Business Area Code" = '239' THEN 'Y' -- Advanced Positioning - 239:INBOUND ON-ROAD
        WHEN "Business Area Code" = '120' THEN 'Y' -- Advanced Positioning - 120:GLOBAL SVCS WARRANTIES, MAINT, SUPPORT
        WHEN "Business Area Code" = '144' THEN 'Y' -- Advanced Positioning - 144:GLOBAL SERVICES PARTS
        WHEN "Business Area Code" = '560' THEN 'Y' -- Advanced Positioning - 560:AG SERVICES
        WHEN "Business Area Code" = '143' THEN 'Y' -- Advanced Positioning - 143:GLOBAL SERVICES REPAIR
        WHEN "Business Area Code" = '236' THEN 'Y' -- Advanced Positioning - 236:TRIMBLE REFURBISHED EQUIPMENT
        WHEN "Business Area Code" = '119' THEN 'Y' -- Advanced Positioning - 119:SURVEY GS
        WHEN "Business Area Code" = '197' THEN 'Y' -- Advanced Positioning - 197:GS SOFTWARE MAINTENANCE ELIM
        WHEN "Business Area Code" = '243' THEN 'Y' -- Advanced Positioning - 243:Service Provider Support
        WHEN "Business Area Code" = '402' THEN 'Y' -- Advanced Positioning - 402:LICENSE COMPLIANCE
        WHEN "Business Area Code" = '300' THEN 'Y' -- Advanced Positioning - 300:AUTOMOTIVE POSITION SOLUTIONS
        WHEN "Business Area Code" = '314' THEN 'Y' -- Advanced Positioning - 314:ON-ROAD (INBOUND AMS)
        WHEN "Business Area Code" = '315' THEN 'Y' -- Advanced Positioning - 315:ON-ROAD (APS)
        WHEN "Business Area Code" = '313' THEN 'Y' -- Advanced Positioning - 313:INTEGRATED PRODUCTS
        WHEN "Business Area Code" = '317' THEN 'Y' -- Advanced Positioning - 317:AUTO-EMBEDDED
        WHEN "Business Area Code" = '318' THEN 'Y' -- Advanced Positioning - 318:AUTO-IVN
        WHEN "Business Area Code" = '319' THEN 'Y' -- Advanced Positioning - 319:BLACKBOX
        WHEN "Business Area Code" = '320' THEN 'Y' -- Advanced Positioning - 320:HORIZONTAL SALES
        WHEN "Business Area Code" = '350' THEN 'Y' -- Advanced Positioning - 350:AUTONOMOUS SECTOR MANAGEMENT
        WHEN "Business Area Code" = '389' THEN 'Y' -- Advanced Positioning - 389:CT
        WHEN "Business Area Code" = '518' THEN 'Y' -- Advanced Positioning - 518:CENTRALIZED AUTONOMY R&D
        WHEN "Business Area Code" = '102' THEN 'Y' -- Advanced Positioning - 102:INTECH OEM
        WHEN "Business Area Code" = '110' THEN 'Y' -- Advanced Positioning - 110:INTECH WIRELESS INFRASTRUCTURE
        WHEN "Business Area Code" = '209' THEN 'Y' -- Advanced Positioning - 209:INTECH-FCI
        WHEN "Business Area Code" = '210' THEN 'Y' -- Advanced Positioning - 210:OFF-ROAD (INBOUND AMS)
        WHEN "Business Area Code" = '109' THEN 'Y' -- Advanced Positioning - 109:INFRASTRUCTURE
        WHEN "Business Area Code" = '167' THEN 'Y' -- Advanced Positioning - 167:NAVIGATION INFRASTRUCTURE
        WHEN "Business Area Code" = '303' THEN 'Y' -- Advanced Positioning - 303:TAP TELECOM
        WHEN "Business Area Code" = '168' THEN 'Y' -- Advanced Positioning - 168:EARTH SYSTEMS
        WHEN "Business Area Code" = '184' THEN 'Y' -- Advanced Positioning - 184:REF TEK
        WHEN "Business Area Code" = '304' THEN 'Y' -- Advanced Positioning - 304:NETWORKED MANAGED SERVICE
        WHEN "Business Area Code" = '105' THEN 'Y' -- Advanced Positioning - 105:TRIMBLE POSITIONING SERVICES
        WHEN "Business Area Code" = '146' THEN 'Y' -- Advanced Positioning - 146:OMNISTAR
        WHEN "Business Area Code" = '191' THEN 'Y' -- Advanced Positioning - 191:TPS ACQUIRED NETWORKS
        WHEN "Business Area Code" = '302' THEN 'Y' -- Advanced Positioning - 302:MIDSTATE TPS
        WHEN "Business Area Code" = '301' THEN 'Y' -- Advanced Positioning - 301:VRS NOW CANADA
        WHEN "Business Area Code" = '204' THEN 'Y' -- Advanced Positioning - 204:AXIO-NET
        WHEN "Business Area Code" = '185' THEN 'Y' -- Unified Field Systems - 185:Field Systems Shared
        WHEN "Business Area Code" = '289' THEN 'Y' -- Unified Field Systems - 289:HORIZONTAL R&D
        WHEN "Business Area Code" = '217' THEN 'Y' -- Military - 217:MILITARY ADVANCED SYSTEMS
        ELSE 'N'
    END AS "Field Systems Business Area Flag"
FROM deduplicated
GROUP BY
    "Natural Account Code",
    "Business Area Code",
    "Base Currency Code",
    "Cost Center Code",
    "Cost Center",
    "Reporting Entity Code",
    "Reporting Entity",
    "GAAP Subsection",
    "GL Divisional Group Description",
    "GL Division Description",
    "GAAP Subsection Description",
    "P&L Category";
