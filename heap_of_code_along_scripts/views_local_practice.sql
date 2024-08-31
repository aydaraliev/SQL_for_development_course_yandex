/* Если таблица создана, удаляем её и пересоздаём.
Опция CASCADE поможет удалить не только сам объект,
но и все объекты, которые созданы на его основе. */
DROP TABLE IF EXISTS clients CASCADE;

CREATE TABLE clients
(
    id       SERIAL PRIMARY KEY,     -- уникальный идентификатор
    fio      CHARACTER VARYING(150), -- фамилия имя отчество пользователя
    phone    CHARACTER VARYING(15),  -- номер телефона пользователя
    address  CHARACTER VARYING(150), -- адрес пользователя
    login    CHARACTER VARYING(50),  -- логин пользователя
    password CHARACTER VARYING(50)   -- пароль пользователя (обычно пароли
    -- дополнительно хешируют, но для простоты запишем его в открытом виде)
);

-- Вставьте тестовые данные в таблицу с данными клиентов.
INSERT INTO clients (fio, phone, address, login, password)
VALUES ('Иванов Иван Иванович', '79990000001',
        'г. Москва, Красная площадь, д. 1', 'IVANOV_II', 'tsartheterrible1530'),
       ('Петров Пётр Петрович', '79990000002',
        'г. Санкт-Петербург, Сенатская площадь, д. 1', 'PETROV_PP', 'piterthegreat1672'),
       ('Васильев Василий Васильевич', '79990000004',
        'г. Сочи, ул. Ленина, д. 1', 'VASILEV', 'vasiliytheblind2003');

SELECT id,
       fio,
       address,
       phone,
       'login: ' || login || '; password: ' || password AS login_password
FROM clients
WHERE fio = 'Иванов Иван Иванович'
  AND phone = '79990000001';

-- представление для клиента USER_INFO
CREATE VIEW v_clients_user_info AS
SELECT id,
       fio,
       phone
FROM clients;

-- представление для клиента AUTHENTICATION
CREATE VIEW v_clients_authentication AS
SELECT login,
       password
FROM clients;

ALTER VIEW v_clients_authentication RENAME TO v_clients_authenticator;

CREATE OR REPLACE VIEW v_clients_user_info AS
SELECT id,
       fio,
       phone,
       address,
       fio || phone || address AS additional_field
FROM clients;

/* Если таблица создана, удалите её и пересоздайте.
Опция CASCADE поможет удалить не только сам объект,
но и все объекты, которые созданы на его основе. */
DROP TABLE IF EXISTS clients CASCADE;
DROP TABLE IF EXISTS addresses CASCADE;

-- Создайте таблицу с адресами
CREATE TABLE IF NOT EXISTS addresses
(
    id       SERIAL PRIMARY KEY, -- уникальный идентификатор
    location CHARACTER VARYING(150)
);

-- Создайте таблицу с данными клиентов
CREATE TABLE IF NOT EXISTS clients
(
    id         SERIAL PRIMARY KEY,                -- уникальный идентификатор
    fio        CHARACTER VARYING(150),            -- ФИО клиента
    phone      CHARACTER VARYING(15),             -- номер телефона клиента
    address_id INTEGER REFERENCES addresses (id), -- id адреса клиента
    login      CHARACTER VARYING(50),             -- логин клиента
    password   CHARACTER VARYING(50)              -- пароль клиента
);

-- Вставьте тестовые данные в таблицу с адресами
INSERT INTO addresses (location)
VALUES ('г. Москва, Красная площадь, д. 1'),
       ('г. Санкт-Петербург, Сенатская площадь, д. 1'),
       ('г. Сочи, ул. Ленина, д. 1');

-- Вставьте тестовые данные в таблицу с данными клиентов
INSERT INTO clients (fio, phone, address_id, login, password)
VALUES ('Иванов Иван Иванович', '79990000001', 1, 'IVANOV_II', 'tsartheterrible1530'),
       ('Петров Пётр Петрович', '79990000002', 2, 'PETROV_PP', 'piterthegreat1672'),
       ('Васильев Василий Васильевич', '79990000004', 3, 'VASILEV_VV', 'vasiliytheblind2003');

-- Представление для сервиса USER_INFO
CREATE VIEW v_clients_user_info AS
SELECT id,
       fio,
       phone,
       address_id
FROM clients;

-- Представление для сервиса AUTHENTICATION
CREATE VIEW v_clients_authentication AS
SELECT id,
       login,
       password
FROM clients;

INSERT INTO v_clients_user_info (fio, phone, address_id)
VALUES ('ФИО нового клиента', '79012344444', 1);

UPDATE v_clients_user_info
SET fio   = 'Фамилия Имя Отчество',
    phone = null
WHERE fio = 'ФИО нового клиента';

DELETE
FROM v_clients_user_info
WHERE phone is null;

INSERT INTO clients (login, password)
VALUES ('ivanov_ii', '123');

UPDATE clients
SET password = '111'
WHERE login = 'ivanov_ii';

DELETE
FROM clients
WHERE password = '111';

INSERT INTO v_clients_authentication (login, password)
VALUES ('ivanov_ii', '123');

UPDATE v_clients_authentication
SET password = '111'
WHERE login = 'ivanov_ii';

DELETE
FROM v_clients_authentication
WHERE password = '111';

INSERT INTO v_clients_authentication (fio, phone, address_id, login, password)
VALUES ('ФИО нового клиента', '79012344444', 1, 'fio', '123');

UPDATE v_clients_authentication
SET phone = '111'
WHERE login = 'ФИО нового клиента';

DELETE
FROM v_clients_authentication
WHERE address_id = 1;

-- Создайте представление v_tmp_clients на основе базовой таблицы clients
CREATE MATERIALIZED VIEW v_tmp_clients AS
SELECT id,
       fio,
       phone
FROM clients;

SELECT *
FROM v_tmp_clients
ORDER BY id;

-- Добавьте тестовые данные в таблицу
INSERT INTO clients (fio, phone)
VALUES ('Платонов Платон Платонович', '79990000003');

-- Обновите запись с id равным 1
UPDATE clients
SET fio   = 'Леонидов Леонид Леонидович',
    phone = '79990000005'
WHERE id = 1;

-- Удалите запись с id равно 2
DELETE
FROM clients
WHERE id = 2;

SELECT *
FROM v_tmp_clients
ORDER BY id;

-- Обновите материализованное представление
REFRESH MATERIALIZED VIEW v_tmp_clients;

-- Посмотрите результат выборки материализованного представления
SELECT *
FROM v_tmp_clients
ORDER BY id;

-- Если таблица существует — удалите её и пересоздайте.
-- Опция CASCADE поможет удалить не только сам объект,
-- но и все объекты, которые созданы на основе этого объекта
DROP TABLE IF EXISTS clients CASCADE;

-- Создайте таблицу clients
CREATE TABLE IF NOT EXISTS clients
(
    id    SERIAL PRIMARY KEY,
    fio   CHARACTER VARYING(150),
    phone CHARACTER VARYING(15)
);
-- Добавьте тестовые данные в таблицу
INSERT INTO clients (fio, phone)
VALUES ('Иванов Иван Иванович', '79990000001'),
       ('Петров Петр Петрович', '79990000002'),
       ('Васильев Василий Васильевич', '79990000004');

CREATE MATERIALIZED VIEW v_tmp_clients AS
SELECT id,
       fio,
       phone
FROM clients;

INSERT INTO clients (fio, phone)
VALUES ('Сидоров Сидор Сидорович', '79990000003');

SELECT COUNT(*)
FROM v_tmp_clients;

-- Удалите таблицы, если они уже существуют
DROP TABLE IF EXISTS clients CASCADE;
DROP TABLE IF EXISTS payments CASCADE;

-- Создайте таблицу clients
CREATE TABLE IF NOT EXISTS clients
(
    id    SERIAL PRIMARY KEY,
    fio   CHARACTER VARYING(150),
    phone CHARACTER VARYING(15)
);

-- Создайте таблицу payments
CREATE TABLE IF NOT EXISTS payments
(
    id         SERIAL PRIMARY KEY,
    client_id  INTEGER REFERENCES clients (id),
    amount     NUMERIC(18, 2),
    created_at TIMESTAMPTZ
);

-- Вставьте 1000 синтетических клиентов в таблицу clients
INSERT INTO clients (fio, phone)
SELECT 'ФИО ' || generate_series     AS fio,
       'Телефон ' || generate_series AS phone
FROM generate_series(1, 1000);

-- Вставьте синтетические записи в таблицу payments
INSERT INTO payments (client_id, amount, created_at)
SELECT client_id,
       amount,
       created_at
FROM (SELECT
          -- Возьмите рандомный id клиентов от 1 до 1000
          1 + (RANDOM() * 999)::INTEGER                     AS client_id,
          -- Возьмите рандомные суммы  от -50000 до +50000
          -50000 + (RANDOM() * 100000)::NUMERIC(18, 2)      AS amount,
          -- Возьмите рандомные даты за прошедший год
          CURRENT_TIMESTAMP - '1 year'::interval * random() AS created_at
      FROM generate_series(1, 20000)) ra
ORDER BY ra.created_at;

SELECT *,
       SUM(amount) OVER (
           PARTITION BY client_id ORDER BY created_at
           ) AS account_balance
FROM payments
WHERE client_id = 1
ORDER BY created_at;

CREATE MATERIALIZED VIEW v_client_account_balance AS
SELECT client_id,
       SUM(amount) AS account_balance
FROM payments
GROUP BY client_id
ORDER BY client_id;

REFRESH MATERIALIZED VIEW v_client_account_balance;

-- Для кредитного отдела
SELECT cl.*,
       cab.account_balance
FROM clients AS cl
         INNER JOIN v_client_account_balance AS cab ON (cl.id = cab.client_id)
WHERE cab.account_balance < -300000;

-- Для отдела новых продуктов
SELECT cl.*,
       cab.account_balance
FROM clients AS cl
         INNER JOIN v_client_account_balance AS cab ON (cl.id = cab.client_id)
WHERE cab.account_balance > 300000;

--Для отдела отчётности
SELECT SUM(CASE WHEN account_balance > 0 THEN account_balance END) AS DEBIT_BALANCE,
       SUM(CASE WHEN account_balance < 0 THEN account_balance END) AS CREDIT_BALANCE,
       SUM(account_balance)                                        AS BALANCE
FROM v_client_account_balance;