-- Пример ожидания пока другая команда не отпустит блокировку
DELETE
FROM students
WHERE full_name = 'Медведев Александр Анатольевич';

DROP TABLE IF EXISTS products CASCADE;
-- Создаём таблицу
CREATE TABLE products
(
    id_product serial,                             -- идентификатор товара
    name       varchar(500)   not null,            -- наименование товара
    price      numeric(15, 4) not null,            -- цена за единицу
    unit       varchar(10)    not null,            -- единицы измерения
    qty        int            not null default (0) -- наличие на складе
);

-- Наполняем минимальными тестовыми данными
INSERT INTO products(name, price, unit, qty)
VALUES ('Щебень гранитный фр. 2-5', 3700, 'тонна', 800),
       ('Щебень известняк фр. 20-40', 1800, 'тонна', 500),
       ('Керамзит фр.10/20', 1850, 'м3', 500),
       ('Песок речной', 2500, 'тонна', 900);

BEGIN;
LOCK TABLE products;
SELECT pg_backend_pid();
ROLLBACK;

BEGIN;
UPDATE balances
SET balance = balance - 50
WHERE client_id = 2;

UPDATE balances
SET balance = balance + 50
WHERE client_id = 1;
