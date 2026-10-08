-- Selecting shipping db

USE shipping_db;

-- Stored procedure for shippments to destination city dallas

CREATE PROCEDURE destination_city_dallas() 
BEGIN
    SELECT *
    FROM shipments
    WHERE
        destination_city = 'dallas';
END