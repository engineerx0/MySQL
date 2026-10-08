-- Selecting shipping db

USE shipping_db;

-- View for cacelled Order
CREATE VIEW cancelled_orders AS
SELECT *
FROM shipments
WHERE
    shipment_status = 'cancelled';

-- View for item having at least weight of 100 kgs

CREATE VIEW weight_atleast_100kgs AS
SELECT *
FROM shipments
WHERE
    weight_kg >= 100;