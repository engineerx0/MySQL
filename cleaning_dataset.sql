-- SQL data cleaning project

CREATE DATABASE shipping_db;

-- Selecting DATABASE shipping_db for use

USE shipping_db;

-- Create a staging table ( we are creating table because we need to define columns with datatypes, and later we will ignore first line)

CREATE TABLE shipments_raw (
    shipment_id VARCHAR(20),
    origin_warehouse VARCHAR(100),
    destination_city VARCHAR(100),
    destination_state VARCHAR(10),
    carrier VARCHAR(50),
    ship_date VARCHAR(30),
    delivery_date VARCHAR(30),
    weight_kg VARCHAR(30),
    freight_cost VARCHAR(30),
    shipment_status VARCHAR(30),
    items_count VARCHAR(30),
    damage_reported VARCHAR(10)
);

-- Run this using an account with sufficient privileges:

SET GLOBAL local_infile = 1;

-- Check the setting:

SHOW GLOBAL VARIABLES LIKE 'local_infile';

-- Import the csv (ignored first line because we need to define table with datatypes)

LOAD DATA LOCAL INFILE '/workspaces/MySQL/dirty_shipments.csv'
INTO TABLE shipments_raw
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    shipment_id,
    origin_warehouse,
    destination_city,
    destination_state,
    carrier,
    ship_date,
    delivery_date,
    weight_kg,
    freight_cost,
    shipment_status,
    items_count,
    damage_reported
);

-- Drop the shipments table as per the requirement

DROP TABLE shipments;

-- Create the final table

CREATE TABLE shipments (
    shipment_id VARCHAR(20) PRIMARY KEY,
    origin_warehouse VARCHAR(100),
    destination_city VARCHAR(100),
    destination_state CHAR(2),
    carrier VARCHAR(50),
    ship_date DATE,
    delivery_date DATE,
    weight_kg DECIMAL(10,2),
    freight_cost DECIMAL(10,2),
    shipment_status VARCHAR(30),
    items_count INT,
    damage_reported VARCHAR(3)
);

-- Clean and insert the data

INSERT INTO shipments (
    shipment_id,
    origin_warehouse,
    destination_city,
    destination_state,
    carrier,
    ship_date,
    delivery_date,
    weight_kg,
    freight_cost,
    shipment_status,
    items_count,
    damage_reported
)
SELECT
    TRIM(shipment_id),

    (SELECT CONCAT(
        UPPER(LEFT(SUBSTRING_INDEX(TRIM(origin_warehouse), ' ', 1), 1)),
        LOWER(SUBSTRING(SUBSTRING_INDEX(TRIM(origin_warehouse), ' ', 1), 2)),
        ' ',
        UPPER(LEFT(SUBSTRING_INDEX(TRIM(origin_warehouse), ' ', -1), 1)),
        LOWER(SUBSTRING(SUBSTRING_INDEX(TRIM(origin_warehouse), ' ', -1), 2))
    )) AS origin_warehouse,
    
    CASE
        WHEN TRIM(destination_city) = '' THEN 'Unknown'
        ELSE CONCAT(
            UPPER(LEFT(SUBSTRING_INDEX(TRIM(destination_city), ' ', 1), 1)),
            LOWER(SUBSTRING(SUBSTRING_INDEX(TRIM(destination_city), ' ', 1), 2)),
            IF(
                TRIM(destination_city) LIKE '% %',
                CONCAT(
                    ' ',
                    UPPER(LEFT(SUBSTRING_INDEX(TRIM(destination_city), ' ', -1), 1)),
                    LOWER(SUBSTRING(SUBSTRING_INDEX(TRIM(destination_city), ' ', -1), 2))
                ),
                ''
            )
        )
    END,

    UPPER(TRIM(destination_state)),

    CASE
        WHEN UPPER(TRIM(carrier)) = 'FASTFREIGHT' THEN 'FastFreight'
        WHEN UPPER(TRIM(carrier)) = 'SPEEDYHAUL' THEN 'SpeedyHaul'
        WHEN UPPER(TRIM(carrier)) = 'QUICKSHIP' THEN 'QuickShip'
        ELSE TRIM(carrier)
    END,

    CASE
        WHEN TRIM(ship_date) = '' THEN NULL
        WHEN TRIM(ship_date) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
            THEN STR_TO_DATE(TRIM(ship_date), '%Y-%m-%d')
        WHEN TRIM(ship_date) REGEXP '^[0-9]{4}/[0-9]{2}/[0-9]{2}$'
            THEN STR_TO_DATE(TRIM(ship_date), '%Y/%m/%d')
        WHEN TRIM(ship_date) REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
            THEN STR_TO_DATE(TRIM(ship_date), '%m/%d/%Y')
        WHEN TRIM(ship_date) REGEXP '^[A-Za-z]+ [0-9]{1,2} [0-9]{4}$'
            THEN STR_TO_DATE(TRIM(ship_date), '%M %e %Y')
        ELSE NULL
    END,

    CASE
        WHEN TRIM(delivery_date) = '' THEN NULL
        WHEN TRIM(delivery_date) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
            THEN STR_TO_DATE(TRIM(delivery_date), '%Y-%m-%d')
        WHEN TRIM(delivery_date) REGEXP '^[0-9]{4}/[0-9]{2}/[0-9]{2}$'
            THEN STR_TO_DATE(TRIM(delivery_date), '%Y/%m/%d')
        WHEN TRIM(delivery_date) REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
            THEN STR_TO_DATE(TRIM(delivery_date), '%m/%d/%Y')
        WHEN TRIM(delivery_date) REGEXP '^[A-Za-z]+ [0-9]{1,2} [0-9]{4}$'
            THEN STR_TO_DATE(TRIM(delivery_date), '%M %e %Y')
        ELSE NULL
    END,

    CAST(NULLIF(TRIM(weight_kg), '') AS DECIMAL(10,2)),
    CAST(NULLIF(TRIM(freight_cost), '') AS DECIMAL(10,2)),
    LOWER(TRIM(shipment_status)),
    CAST(NULLIF(TRIM(items_count), '') AS SIGNED),

    CASE
        WHEN UPPER(TRIM(damage_reported)) IN ('', 'NULL') THEN NULL
        ELSE UPPER(TRIM(damage_reported))
    END
FROM shipments_raw;
