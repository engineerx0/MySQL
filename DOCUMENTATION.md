# Shipping Data Cleaning Project

## 1. Project Overview

This project imports shipment data from a CSV file into MySQL, stores the raw data in a staging table, cleans inconsistent values, and inserts the cleaned data into a final production table.

The workflow is:

1. Create a database.
2. Create a staging table.
3. Import the CSV file.
4. Create a cleaned table with appropriate data types.
5. Standardize and convert the raw values.
6. Insert the cleaned data into the final table.

---

## 2. Create and Select the Database

```sql
CREATE DATABASE shipping_db;

USE shipping_db;
```

The `shipping_db` database stores both the raw and cleaned shipment data.

The `USE` statement makes `shipping_db` the active database for subsequent queries.

---

## 3. Create the Staging Table

```sql
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
```

The staging table stores all CSV values as text.

This is useful because the source file contains inconsistent data, including:

- Multiple date formats
- Empty values
- Text values such as `NULL`
- Inconsistent capitalization
- Extra spaces
- Numeric values that need validation

Keeping the staging columns as `VARCHAR` prevents the initial import from failing because of formatting problems.

---

## 4. Enable Local File Loading

```sql
SET GLOBAL local_infile = 1;

SHOW GLOBAL VARIABLES LIKE 'local_infile';
```

`LOAD DATA LOCAL INFILE` requires local file loading to be enabled on the MySQL server.

The `SHOW GLOBAL VARIABLES` query verifies whether the setting is enabled.

The client connection may also need to enable local file loading. For example:

```bash
mysql --local-infile=1 -u your_username -p
```

The user running `SET GLOBAL local_infile = 1` may need appropriate administrative privileges.

---

## 5. Import the CSV File

```sql
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
```

### Import settings

| Setting | Purpose |
|---|---|
| `LOCAL INFILE` | Reads the file from the client or workspace machine |
| `FIELDS TERMINATED BY ','` | Specifies that the CSV uses commas |
| `OPTIONALLY ENCLOSED BY '"'` | Handles values enclosed in double quotes |
| `LINES TERMINATED BY '\n'` | Indicates that each row ends with a newline |
| `IGNORE 1 ROWS` | Skips the CSV header |
| Column list | Maps CSV fields to table columns |

After importing, verify the staging table:

```sql
SELECT COUNT(*) AS row_count
FROM shipments_raw;

SELECT *
FROM shipments_raw
LIMIT 5;
```

---

## 6. Create the Final Shipments Table

```sql
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
```

Unlike the staging table, the final table uses appropriate data types:

- `DATE` for shipment and delivery dates
- `DECIMAL(10,2)` for weight and freight cost
- `INT` for item count
- `CHAR(2)` for state codes
- `shipment_id` as the primary key

The primary key ensures that each shipment ID is unique.

---

## 7. Clean and Insert the Data

```sql
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
    TRIM(origin_warehouse),
    NULLIF(TRIM(destination_city), ''),
    UPPER(TRIM(destination_state)),
    TRIM(carrier),

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
```

---

## 8. Data Cleaning Rules

### Text cleanup

```sql
TRIM(column_name)
```

Removes leading and trailing spaces.

For example:

```text
'  Los Angeles  ' → 'Los Angeles'
```

### State standardization

```sql
UPPER(TRIM(destination_state))
```

Converts state codes to uppercase.

For example:

```text
'il' → 'IL'
tx → TX
```

### Shipment status standardization

```sql
LOWER(TRIM(shipment_status))
```

Converts shipment statuses to lowercase.

For example:

```text
'Delivered' → 'delivered'
'DELIVERED' → 'delivered'
'In Transit' → 'in transit'
```

### Empty values

```sql
NULLIF(TRIM(destination_city), '')
```

Converts an empty string into SQL `NULL`.

### Date conversion

The query supports these formats:

```text
2024-01-10
2024/01/22
01/15/2024
Feb 10 2024
```

The `REGEXP` condition identifies the format, and `STR_TO_DATE()` converts the value into a MySQL `DATE`.

### Numeric conversion

```sql
CAST(NULLIF(TRIM(weight_kg), '') AS DECIMAL(10,2))
```

Converts text values into numeric values while turning blank values into `NULL`.

### Damage report conversion

```sql
CASE
    WHEN UPPER(TRIM(damage_reported)) IN ('', 'NULL') THEN NULL
    ELSE UPPER(TRIM(damage_reported))
END
```

Converts:

```text
NULL → SQL NULL
No → NO
no → NO
Yes → YES
```

---

## 9. Verify the Cleaned Data

Check the final table:

```sql
SELECT *
FROM shipments;
```

Check the number of rows:

```sql
SELECT COUNT(*) AS shipment_count
FROM shipments;
```

Check missing values:

```sql
SELECT *
FROM shipments
WHERE destination_city IS NULL
   OR ship_date IS NULL
   OR delivery_date IS NULL
   OR freight_cost IS NULL;
```

Check standardized statuses:

```sql
SELECT DISTINCT shipment_status
FROM shipments;
```

Check standardized states:

```sql
SELECT DISTINCT destination_state
FROM shipments;
```

Check potentially invalid numeric values:

```sql
SELECT *
FROM shipments
WHERE weight_kg < 0
   OR freight_cost < 0
   OR items_count < 0;
```

---

## 10. Example Analysis Queries

Total freight cost by carrier:

```sql
SELECT
    carrier,
    COUNT(*) AS shipment_count,
    SUM(freight_cost) AS total_freight_cost
FROM shipments
GROUP BY carrier;
```

Delivered shipments:

```sql
SELECT *
FROM shipments
WHERE shipment_status = 'delivered';
```

Shipments with reported damage:

```sql
SELECT *
FROM shipments
WHERE damage_reported = 'YES';
```

Average shipment weight by destination state:

```sql
SELECT
    destination_state,
    AVG(weight_kg) AS average_weight_kg
FROM shipments
GROUP BY destination_state;
```

Delivery duration:

```sql
SELECT
    shipment_id,
    DATEDIFF(delivery_date, ship_date) AS delivery_days
FROM shipments
WHERE ship_date IS NOT NULL
  AND delivery_date IS NOT NULL;
```

---

## 11. Important Notes

If you rerun the cleaning query, existing rows may cause duplicate primary-key errors. Clear the final table first:

```sql
TRUNCATE TABLE shipments;
```

Then run the `INSERT INTO shipments ... SELECT ...` query again.

If you want to reload the raw CSV from the beginning, clear the staging table first:

```sql
TRUNCATE TABLE shipments_raw;
```

Then run the `LOAD DATA LOCAL INFILE` command again.