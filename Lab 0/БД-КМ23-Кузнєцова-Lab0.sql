-- Database: Shop

-- DROP DATABASE IF EXISTS "Shop";

CREATE DATABASE "Shop"
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Russian_Ukraine.1251'
    LC_CTYPE = 'Russian_Ukraine.1251'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

--Table
CREATE TABLE Products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    price NUMERIC(10, 2) NOT NULL CHECK (price >= 0)
);

CREATE TABLE Customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL
);

CREATE TABLE Orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES Customers(customer_id),
    product_id INTEGER NOT NULL REFERENCES Products(product_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0)
);

--Insert
INSERT INTO Products (name, category, price) VALUES
('Laptop', 'Electronics', 1000.00),
('Smartphone', 'Electronics', 500.00),
('Headphones', 'Electronics', 100.00),
('Mouse', 'Electronics', 25.00),
('Keyboard', 'Electronics', 45.00);

INSERT INTO Customers (name, city) VALUES
('John Doe', 'New York'),
('Jane Smith', 'Los Angeles'),
('Bob Johnson', 'New York');

INSERT INTO Orders (customer_id, product_id, quantity) VALUES
(1, 1, 2),  -- John Doe -> Laptop x2
(1, 2, 1),  -- John Doe -> Smartphone x1
(2, 1, 1),  -- Jane Smith -> Laptop x1
(3, 3, 3),  -- Bob Johnson -> Headphones x3
(2, 2, 2);  -- Jane Smith -> Smartphone x2

SELECT * FROM Products;
SELECT * FROM Customers;
SELECT
    o.order_id,
    c.name AS customer_name,
    p.name AS product_name,
    o.quantity
FROM Orders o
JOIN Customers c ON o.customer_id = c.customer_id
JOIN Products p ON o.product_id = p.product_id
ORDER BY o.order_id;

-- 1. Агрегатні функції
-- Запит 1: Підрахунок загальної суми замовлень по категоріях продуктів
SELECT
	p.category,
	COUNT(o.order_id) as total_orders,
	SUM(o.quantity) as total_quantity,
	ROUND(AVG(p.price * o.quantity), 2) as avg_order_value
FROM Products p
JOIN Orders o ON p.product_id = o.product_id
GROUP BY p.category;

UPDATE Products SET price = 499.99 WHERE name = 'Laptop';
UPDATE Products SET price = 300.00 WHERE name = 'Smartphone';
UPDATE Products SET price = 299.99 WHERE name = 'Headphones';
--Знову запустити Запит 1

-- 2. Перетин таблиці з собою
-- Запит 2: Знайти пари клієнтів з одного міста
SELECT
c1.name as customer1,
c2.name as customer2,
c1.city
FROM Customers c1
JOIN Customers c2 ON c1.city = c2.city AND c1.customer_id < c2.customer_id;

-- 3. Різні типи JOIN
-- Запит 3: Показати всі продукти та їх замовлення (включаючи ті, що не мають замовлень)
SELECT
p.name as product_name,
COALESCE(COUNT(o.order_id), 0) as orders_count,
COALESCE(SUM(o.quantity), 0) as total_quantity
FROM Products p
LEFT JOIN Orders o ON p.product_id = o.product_id
GROUP BY p.name;

-- Запит 4: Повне об'єднання клієнтів та їх замовлень
SELECT
c.name,
o.order_id,
p.name as product_name,
o.quantity
FROM Customers c
LEFT JOIN Orders o ON c.customer_id = o.customer_id
LEFT JOIN Products p ON o.product_id = p.product_id
UNION ALL
SELECT
c.name,
o.order_id,
p.name as product_name,
o.quantity
FROM Orders o
RIGHT JOIN Customers c ON c.customer_id = o.customer_id
RIGHT JOIN Products p ON o.product_id = p.product_id
WHERE c.customer_id IS NULL;