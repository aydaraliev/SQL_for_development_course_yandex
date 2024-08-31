BEGIN;
SELECT MAX(price)
FROM products;
COMMIT;

BEGIN;
UPDATE products
SET price = 100.00
WHERE name = 'Product 5';
COMMIT;

CREATE TABLE warehouse_movements
(
    id          SERIAL PRIMARY KEY,
    store_id    INTEGER,
    product_id  CHARACTER(5),
    quantity    INTEGER,
    update_date TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_actual   BOOL                        DEFAULT TRUE
);

INSERT INTO warehouse_movements (store_id,
                                 product_id,
                                 quantity)
VALUES (1, 'A', 100),
       (1, 'B', 100),
       (2, 'A', 200),
       (2, 'B', 200);

BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Переместите все товары со склада 2 на склад 1 и промаркируйте как товар 'C':
INSERT INTO warehouse_movements (store_id,
                                 product_id,
                                 quantity)
SELECT 1, 'C', qnt
FROM (SELECT sum(quantity) AS qnt
      FROM warehouse_movements
      WHERE store_id = 2) AS t;

-- Укажите, что записи для склада 1 стали неактуальны:
UPDATE warehouse_movements
SET is_actual = FALSE
WHERE store_id = 1;

COMMIT;

DROP TABLE users CASCADE;
CREATE TABLE users
(
    id      INTEGER PRIMARY KEY,
    name    VARCHAR(50),
    balance NUMERIC(10, 2)
);
DROP TABLE operations CASCADE;
CREATE TABLE operations
(
    id      SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users (id),
    amount  NUMERIC(10, 2)
);

INSERT INTO users (id, name, balance)
VALUES (1, 'User 1', 100.00),
       (2, 'User 2', 200.00),
       (3, 'User 3', 300.00),
       (4, 'User 4', 400.00),
       (5, 'User 5', 500.00);
INSERT INTO operations (user_id, amount)
VALUES (1, 550.00),
       (2, 100.00),
       (2, 200.00),
       (3, 150.00),
       (4, 200.00),
       (4, 50.00),
       (5, 250.00);

BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- Calculate the sum of operations for each user and update the balance
WITH calculated_balances AS (SELECT u.id                                   AS user_id,
                                    u.balance + COALESCE(SUM(o.amount), 0) AS new_balance
                             FROM users u
                                      LEFT JOIN
                                  operations o ON u.id = o.user_id
                             GROUP BY u.id)
UPDATE users
SET balance = calculated_balances.new_balance
FROM calculated_balances
WHERE users.id = calculated_balances.user_id;

-- Add a 10% bonus to the final balance and update the users table
UPDATE users
SET balance = balance * 1.10;
COMMIT;

INSERT INTO users (id, name, balance)
VALUES (6, 'User 6', 100.00);

INSERT INTO operations (user_id, amount)
VALUES (6, 100.00),
       (6, 200.00);

BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
WITH calculated_balances AS (SELECT u.id                                   AS user_id,
                                    u.balance + COALESCE(SUM(o.amount), 0) AS new_balance
                             FROM users u
                                      LEFT JOIN
                                  operations o ON u.id = o.user_id
                             GROUP BY u.id)
UPDATE users
SET balance = calculated_balances.new_balance
FROM calculated_balances
WHERE users.id = calculated_balances.user_id;

INSERT INTO users (id, name, balance)
VALUES (7, 'User 7', 700.00);

UPDATE users
SET balance = balance * 1.10;

COMMIT;



