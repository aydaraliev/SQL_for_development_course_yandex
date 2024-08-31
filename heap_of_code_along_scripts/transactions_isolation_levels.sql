CREATE TABLE accounts
(
    id             SERIAL PRIMARY KEY,
    account_number VARCHAR(255)   NOT NULL,
    balance        DECIMAL(12, 2) NOT NULL CHECK (balance >= 0),
    last_update    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO accounts (account_number, balance, last_update)
VALUES ('BG22UBBS890', 5000.00, '2023-05-28 00:00:00'),
       ('BG79UBBS901', 3000.00, '2023-05-21 00:00:00'),
       ('BG31UBBS012', 15000.00, '2023-05-22 00:00:00');

CREATE TABLE account_transactions
(
    id                 SERIAL PRIMARY KEY,
    account_id         INTEGER REFERENCES accounts (id),
    transaction_amount DECIMAL(12, 2) NOT NULL CHECK (transaction_amount > 0),
    transaction_type   CHAR(1)        NOT NULL,
    created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO account_transactions
    (account_id, transaction_amount, transaction_type, created_at)
VALUES (1, 1000.00, 'D', '2023-05-30 00:00:00'),
       (1, 500.00, 'W', '2023-05-29 00:00:00'),
       (2, 1500.00, 'D', '2023-05-31 00:00:00'),
       (3, 5000.00, 'W', '2023-05-30 00:00:00');

BEGIN; -- открываем транзакцию
UPDATE accounts
SET balance     = balance - 500,
    last_update = CURRENT_TIMESTAMP
WHERE account_number = 'BG22UBBS890';

UPDATE accounts
SET balance     = balance + 500,
    last_update = CURRENT_TIMESTAMP
WHERE account_number = 'BG31UBBS012';

INSERT INTO account_transactions
    (account_id, transaction_amount, transaction_type)
VALUES (1, 500, 'W');

INSERT INTO account_transactions
    (account_id, transaction_amount, transaction_type)
VALUES (3, 500, 'D');

INSERT INTO account_transactions
    (account_id, transaction_amount, transaction_type)
VALUES (8, 500, 'W');

COMMIT; -- завершаем транзакцию

ROLLBACK;

CREATE TABLE household_products
(
    id             INTEGER PRIMARY KEY,
    product_desc   VARCHAR(255)                        NOT NULL,
    product_amount SMALLINT                            NOT NULL,
    modify_date    TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

INSERT INTO household_products (id, product_desc, product_amount, modify_date)
VALUES (1, 'Тостер', 10, '2023-06-09 10:00:00'),
       (2, 'Микроволновая печь', 5, '2023-06-09 11:30:00'),
       (3, 'Кофеварка', 15, '2023-06-09 12:45:00'),
       (4, 'Пылесос', 8, '2023-06-09 09:15:00'),
       (5, 'Утюг', 12, '2023-06-09 13:20:00');

BEGIN;
INSERT INTO household_products (id, product_desc, product_amount)
VALUES (9, 'Электрочайник', 11);

INSERT INTO household_products (id, product_desc, product_amount)
VALUES (10, 'Хлебопечка', 4);

-- SAVEPOINT id12;
-- INSERT INTO household_products (id, product_desc, product_amount)
-- VALUES (1, 'Пылесос ручной', 3);
--
-- INSERT INTO household_products (id, product_desc, product_amount)
-- VALUES (2, 'Мясорубка', 8);

-- ROLLBACK TO SAVEPOINT id12;
-- RELEASE SAVEPOINT id12;

INSERT INTO household_products (id, product_desc, product_amount)
VALUES (13, 'Соковыжималка', 6);

INSERT INTO household_products (id, product_desc, product_amount)
VALUES (14, 'Кофемолка', 9);
COMMIT;

ROLLBACK;

SELECT CAST(EXTRACT(EPOCH FROM (MAX(modify_date) - MIN(modify_date))) AS INT) AS diff
FROM household_products
WHERE id > 5;

DROP TABLE IF EXISTS products CASCADE;

CREATE TABLE products
(
    name  VARCHAR(50),
    price NUMERIC(10, 2)
);

INSERT INTO products (name, price)
VALUES ('Product 1', 12.50),
       ('Product 2', 10.40),
       ('Product 3', 7.99),
       ('Product 4', 14.99);

BEGIN;
SHOW transaction_isolation;
SELECT MAX(price)
FROM products;
SHOW transaction_isolation;

INSERT INTO products (name, price)
VALUES ('Product 5', 50.40);
SELECT MAX(price)
FROM products;
COMMIT;

BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price)
FROM products;
COMMIT;

BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Переместите товары со склада 1 на склад 2 и промаркируйте как товар 'C':
INSERT INTO warehouse_movements (store_id,
                                 product_id,
                                 quantity)
SELECT 2, 'C', qnt
FROM (SELECT SUM(quantity) AS qnt
      FROM warehouse_movements
      WHERE store_id = 1) AS t;

-- Укажите, что записи для склада 2 стали неактуальны:
UPDATE warehouse_movements
SET is_actual = FALSE
WHERE store_id = 2;

COMMIT;

INSERT INTO users(id, name, balance)
VALUES (6, 'User 6', 100);

INSERT INTO operations(user_id, amount)
VALUES (6, 100),
       (6, 200);