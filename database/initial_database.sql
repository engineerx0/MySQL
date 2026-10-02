-- ==========================================
-- STORE DATABASE - SAMPLE DATA
-- ==========================================
CREATE DATABASE store_database;

USE store_database;
-- Test change

-- ==========================================
-- 1. CUSTOMERS
-- ==========================================

CREATE TABLE IF NOT EXISTS customers (
customer_id INT AUTO_INCREMENT PRIMARY KEY,
first_name VARCHAR(50) NOT NULL,
last_name VARCHAR(50) NOT NULL,
email VARCHAR(100) UNIQUE NOT NULL,
city VARCHAR(50),
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO customers (first_name, last_name, email, city)
VALUES
('Rahul', 'Sharma', 'rahul@gmail.com', 'Delhi'),
('Priya', 'Verma', 'priya@gmail.com', 'Mumbai'),
('Amit', 'Patel', 'amit@gmail.com', 'Ahmedabad'),
('Sneha', 'Reddy', 'sneha@gmail.com', 'Hyderabad'),
('Arjun', 'Mehta', 'arjun@gmail.com', 'Pune'),
('Neha', 'Singh', 'neha@gmail.com', 'Delhi'),
('Vikram', 'Joshi', 'vikram@gmail.com', 'Jaipur'),
('Ananya', 'Iyer', 'ananya@gmail.com', 'Chennai');

-- ==========================================
-- 2. CATEGORIES
-- ==========================================

CREATE TABLE IF NOT EXISTS categories (
category_id INT AUTO_INCREMENT PRIMARY KEY,
category_name VARCHAR(100) NOT NULL UNIQUE
);

INSERT INTO categories (category_name)
VALUES
('Electronics'),
('Accessories'),
('Furniture'),
('Stationery');

-- ==========================================
-- 3. PRODUCTS
-- ==========================================

CREATE TABLE IF NOT EXISTS products (
product_id INT AUTO_INCREMENT PRIMARY KEY,
product_name VARCHAR(150) NOT NULL,
category_id INT,
price DECIMAL(10,2) NOT NULL,
stock INT NOT NULL DEFAULT 0,
FOREIGN KEY (category_id)
REFERENCES categories(category_id)
);

INSERT INTO products (product_name, category_id, price, stock)
VALUES
('Laptop', 1, 65000.00, 15),
('Smartphone', 1, 30000.00, 25),
('Monitor', 1, 15000.00, 12),
('Keyboard', 2, 1500.00, 50),
('Mouse', 2, 800.00, 70),
('Headphones', 2, 2500.00, 30),
('Office Chair', 3, 8500.00, 10),
('Desk', 3, 12000.00, 8),
('Notebook', 4, 100.00, 200),
('Pen Set', 4, 250.00, 100);

-- ==========================================
-- 4. ORDERS
-- ==========================================

CREATE TABLE IF NOT EXISTS orders (
order_id INT AUTO_INCREMENT PRIMARY KEY,
customer_id INT NOT NULL,
order_date DATE NOT NULL,
status ENUM('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled')
DEFAULT 'Pending',
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id)
);

INSERT INTO orders (customer_id, order_date, status)
VALUES
(1, '2026-09-01', 'Delivered'),
(2, '2026-09-02', 'Shipped'),
(3, '2026-09-03', 'Delivered'),
(1, '2026-09-05', 'Processing'),
(4, '2026-09-06', 'Delivered'),
(5, '2026-09-07', 'Pending'),
(6, '2026-09-08', 'Delivered'),
(2, '2026-09-09', 'Cancelled'),
(7, '2026-09-10', 'Shipped'),
(8, '2026-09-11', 'Processing');

-- ==========================================
-- 5. ORDER ITEMS
-- ==========================================

CREATE TABLE IF NOT EXISTS order_items (
order_item_id INT AUTO_INCREMENT PRIMARY KEY,
order_id INT NOT NULL,
product_id INT NOT NULL,
quantity INT NOT NULL,
unit_price DECIMAL(10,2) NOT NULL,
FOREIGN KEY (order_id)
    REFERENCES orders(order_id),

FOREIGN KEY (product_id)
    REFERENCES products(product_id)
);

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES
(1, 1, 1, 65000.00),
(1, 4, 2, 1500.00),
(2, 2, 1, 30000.00),
(2, 5, 1, 800.00),
(3, 3, 2, 15000.00),
(3, 6, 1, 2500.00),
(4, 5, 2, 800.00),
(4, 9, 10, 100.00),
(5, 7, 1, 8500.00),
(5, 8, 1, 12000.00),
(6, 10, 4, 250.00),
(7, 1, 1, 65000.00),
(7, 6, 2, 2500.00),
(8, 2, 1, 30000.00),
(9, 3, 1, 15000.00),
(9, 4, 1, 1500.00),
(10, 8, 1, 12000.00);

-- ==========================================
-- 6. PAYMENTS
-- ==========================================

CREATE TABLE IF NOT EXISTS payments (
payment_id INT AUTO_INCREMENT PRIMARY KEY,
order_id INT NOT NULL,
amount DECIMAL(10,2) NOT NULL,
payment_method ENUM('UPI', 'Card', 'Net Banking', 'Cash')
NOT NULL,
payment_status ENUM('Pending', 'Completed', 'Failed', 'Refunded')
DEFAULT 'Pending',
FOREIGN KEY (order_id)
    REFERENCES orders(order_id)
);

INSERT INTO payments (order_id, amount, payment_method, payment_status)
VALUES
(1, 68000.00, 'UPI', 'Completed'),
(2, 30800.00, 'Card', 'Completed'),
(3, 32500.00, 'Net Banking', 'Completed'),
(4, 2600.00, 'UPI', 'Pending'),
(5, 20500.00, 'Card', 'Completed'),
(6, 1000.00, 'UPI', 'Pending'),
(7, 70000.00, 'Card', 'Completed'),
(8, 30000.00, 'UPI', 'Refunded'),
(9, 16500.00, 'Net Banking', 'Completed'),
(10, 12000.00, 'UPI', 'Pending');
