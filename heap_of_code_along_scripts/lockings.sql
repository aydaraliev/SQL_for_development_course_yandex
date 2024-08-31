DROP TABLE IF EXISTS students;
CREATE TABLE students
(
    student_id    SERIAL,
    full_name     VARCHAR(300)  NOT NULL,
    phone         VARCHAR(20)   NOT NULL,
    address       VARCHAR(300)  NULL,
    average_score NUMERIC(6, 2) NULL -- средний балл
);

INSERT INTO students(full_name, phone, address)
VALUES ('Медведев Александр Анатольевич', '+7(111)111-11-11', NULL),
       ('Картошкина Вера Олеговна', '+7(888)888-88-88', 'Новосибирск'),
       ('Котов Сергей Дмитриевич', '+7(777)777-77-77', 'Москва'),
       ('Зайцев Андрей Алексеевич', '+7(666)666-66-66', NULL),
       ('Туя Аркадий Эрнестович', '+7(555)555-55-55', 'Ялта'),
       ('Сишарпов Николай Анатольевич', '+7(444)444-44-44', NULL),
       ('Иванов Андрей Фёдорович', '+7(333)333-33-33', NULL);

DROP TABLE IF EXISTS payments CASCADE;

CREATE TABLE payments
(
    student_id   INT  NOT NULL,
    payment_date DATE NOT NULL,
    amount       DECIMAL(9, 2)
);
-- Для краткости запроса эту таблицу заполните одинаковыми данными по всем студентам
INSERT INTO payments
SELECT student_id, CURRENT_DATE, 100000
FROM students;

BEGIN;
SELECT full_name, average_score
FROM students
WHERE full_name IN ('Медведев Александр Анатольевич', 'Иванов Андрей Фёдорович')
    FOR NO KEY UPDATE;

SELECT *
FROM students
WHERE full_name = 'Медведев Александр Анатольевич';

UPDATE students
SET average_score = 5
WHERE full_name IN ('Медведев Александр Анатольевич', 'Иванов Андрей Фёдорович');

COMMIT;

BEGIN;
SELECT p.*
FROM students s
         INNER JOIN payments AS p ON s.student_id = p.student_id
WHERE s.full_name = 'Медведев Александр Анатольевич'
    FOR NO KEY UPDATE OF p; -- блокируем выбранные строки в таблице payments

ROLLBACK;

SELECT c.relname,  -- имя таблицы
       l.pid,      -- идентификатор процесса
       l.mode,     -- режим блокировки
       l.granted,  -- выдана ли блокировка
       l.waitstart -- время начала ожидания выдачи блокировки
FROM pg_locks l
         LEFT JOIN pg_class c ON c.oid = l.relation
WHERE c.relname = 'products'
  AND l.pid = 984; -- сюда подставьте ваш pid

SELECT *
FROM products
WHERE name = 'Песок речной';

SELECT pg_backend_pid()

SELECT
    c.relname, -- имя таблицы
    l.pid,     -- идентификатор процесса
    l.mode,    -- режим блокировки
    l.granted, -- выдана ли блокировка
    l.waitstart, -- время начала ожидания выдачи блокировки
    pg_blocking_pids(l.pid) -- id процесса, который блокирует текущий
FROM pg_locks l
LEFT JOIN pg_class c ON c.oid = l.relation
WHERE c.relname = 'products';

ROLLBACK;

BEGIN;
-- добавлен NOWAIT, чтобы не ждать, пока таблица освободится
LOCK TABLE products in ACCESS SHARE MODE NOWAIT;
SELECT * FROM products WHERE name like 'Керамзит%';
COMMIT;

CREATE TABLE balances(
    client_id INT,
    balance DECIMAL(10,2)
);

INSERT INTO balances
VALUES
    (1, 1000.00),
    (2, 200.00);

BEGIN;
UPDATE balances
SET balance = balance-100
WHERE client_id = 1;

UPDATE balances
SET balance = balance+100
WHERE client_id = 2;

CREATE TABLE orders
(
    id INT PRIMARY KEY,
    client_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    delivery_price DECIMAL(10,2) NOT NULL,
    create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    state VARCHAR(20)
);

INSERT INTO orders(id, client_id, amount, delivery_price, create_date, state)
VALUES
    (1, 5, 5000, 500, '2023-09-20', 'доставлен'),
    (2, 8, 15000, 0, '2023-09-25', 'доставляется'),
    (3, 5, 1000, 500, '2023-09-25', 'готов к доставке'),
    (4, 2, 2500, 500, '2023-09-26', 'готов к доставке'),
    (5, 3, 750, 0, '2023-09-27', 'готов к доставке'),
    (6, 7, 8955, 500, '2023-09-27', 'готов к доставке'),
    (7, 9, 900, 0, '2023-09-28', 'готов к доставке'),
    (8, 4, 7800, 500, '2023-09-29', 'сборка'),
    (9, 2, 500, 0, '2023-09-29', 'готов к доставке'),
    (10, 1, 1000, 500, '2023-09-30', 'готов к доставке'),
    (11, 10, 5400, 500, '2023-09-30', 'готов к доставке'),
    (12, 9, 3600, 500, '2023-09-30', 'готов к доставке'),
    (13, 4, 11200, 0, '2023-09-30', 'сборка');


BEGIN;

LOCK TABLE orders IN ACCESS EXCLUSIVE MODE;

COMMIT;

BEGIN;

-- Установить блокировку на таблицу в режиме SHARE
LOCK TABLE orders IN SHARE MODE;

-- Держим транзакцию открытой, чтобы блокировка оставалась активной
-- Эта блокировка будет действовать до тех пор, пока не будет выполнен COMMIT или ROLLBACK
-- Вы можете оставить это окно открытым, чтобы сохранить блокировку на весь день

-- Пример запроса на чтение для менеджера
SELECT * FROM orders;

-- Не выполняйте COMMIT или ROLLBACK, чтобы блокировка оставалась активной
-- Когда нужно снять блокировку, выполните COMMIT или ROLLBACK
COMMIT;

BEGIN;

-- Блокируем заказы клиента с client_id = 4 для пересчета стоимости
BEGIN;
SELECT * FROM orders
WHERE client_id = 4
FOR NO KEY UPDATE;

-- Применяем скидку 20% на каждый второй товар в заказах клиента
UPDATE orders
SET amount = amount * 0.8
WHERE client_id = 4 AND state != 'доставлен' AND mod(id, 2) = 0;

-- Завершаем транзакцию
COMMIT;





