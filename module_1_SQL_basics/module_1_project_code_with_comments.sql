/* Ваша задача — нормализовать и структурировать существующие сырые данные, а потом
   написать несколько запросов для получения информации из БД. Для этого перенесите
   сырые данные в PostgreSQL. Вы можете выполнить работу в любом удобном для вас клиенте.
   Результатом станет набор SQL-команд, объединённых в единый скрипт. */

-- Создание схемы
DROP SCHEMA raw_data CASCADE;
CREATE SCHEMA raw_data;
-- Создание таблицы
DROP TABLE IF EXISTS raw_data.sales;
CREATE TABLE raw_data.sales
(
    id                   INT,
    auto                 VARCHAR(400),
    gasoline_consumption FLOAT CHECK (gasoline_consumption < 100),
    price                DECIMAL(9, 2),
    date                 DATE,
    person               VARCHAR(400),
    phone                VARCHAR(30),
    discount             DECIMAL(4, 2),
    brand_origin         VARCHAR(400)
);
-- Вставка данных
-- docker ps
-- docker cp ./module_1_SQL_basics/cars.csv postgres_practicum:/home/sprint_1/
-- docker exec -it postgres_practicum bash
-- psql -U postgres -d sprint_1
COPY raw_data.sales FROM '/home/sprint_1/cars.csv' DELIMITER ',' CSV HEADER NULL 'null';
-- Проверка вставки
SELECT *
FROM raw_data.sales
LIMIT 5;
-- Проверим стобцы на наличие пропусков;
SELECT count(*)                    as row_count,
       count(id)                   as id,
       count(price)                as price,
       count(date)                 as date,
       count(gasoline_consumption) as gasoline_consumption,
       count(person)               as person,
       count(phone)                as phone,
       count(discount)             as discount,
       count(brand_origin)         as brand_origin
FROM raw_data.sales;
-- Явные пропуски в столбцах gasoline consumption и brand_origin. Посмотрим что это за строки.
SELECT *
FROM raw_data.sales
WHERE brand_origin IS NULL;
-- Все пропуски в столбце brand_origin можно заменить на Germany, так как
-- марка автомобиля указаная в столбце auto это Porsche.
UPDATE raw_data.sales
SET brand_origin = 'Germany'
WHERE brand_origin IS NULL;
-- Создадим схему car_shop
DROP SCHEMA car_shop CASCADE;
CREATE SCHEMA car_shop;
-- Создадим таблицу clients
DROP TABLE IF EXISTS car_shop.clients CASCADE;
CREATE TABLE car_shop.clients
(
    client_id SERIAL PRIMARY KEY NOT NULL,
    name      VARCHAR(400)       NOT NULL, -- имя клиента, взял с запасом. В латинской америке вот по 10-15 имён бывает у людей.
    last_name VARCHAR(400)       NOT NULL, -- фамилия клиента, взял с запасом.
    phone     VARCHAR(30)        NOT NULL  -- телефон клиента, взял с запасом, текстовое поле что-бы не хранить большие цифры, да и формат у номеров плавает, замучаешься парсить.
);
-- Создадим таблицу countries, поскольку в исходной таблице были пропуски
-- в столбце brand_origin, то предположим что пропуски возможны и в дальнейшем.
-- Задаим значение по умолчанию 'unknown' для этого столбца.
DROP TABLE IF EXISTS car_shop.countries CASCADE;
CREATE TABLE car_shop.countries
(
    country_id   SERIAL PRIMARY KEY             NOT NULL,
    country_name VARCHAR(400) DEFAULT 'unknown' NOT NULL
);
-- Создадим таблицу brands
DROP TABLE IF EXISTS car_shop.brands CASCADE;
CREATE TABLE car_shop.brands
(
    brand_id   SERIAL PRIMARY KEY NOT NULL,
    brand_name VARCHAR(400)       NOT NULL, -- название бренда с запасом, вдруг исландцы начнут производить автомобили.
    country_id INT                NOT NULL, -- страна производитель, внешний ключ
    CONSTRAINT fk_country_id
        FOREIGN KEY (country_id)
            REFERENCES car_shop.countries (country_id)
);
-- Создадим таблицу colours
DROP TABLE IF EXISTS car_shop.colours CASCADE;
CREATE TABLE car_shop.colours
(
    colour_id SERIAL PRIMARY KEY NOT NULL,
    colour    VARCHAR(15)        NOT NULL
);
-- Создадим таблицу car_models
DROP TABLE IF EXISTS car_shop.car_models CASCADE;
CREATE TABLE car_shop.car_models
(
    model_id             SERIAL PRIMARY KEY                                 NOT NULL,
    model_name           VARCHAR(400)                                       NOT NULL, -- с запасом
    gasoline_consumption FLOAT CHECK (gasoline_consumption < 100) DEFAULT 0 NULL,     --Проверка что расход меньше 100.
    colour_id            INT                                                NOT NULL, -- цвет автомобиля.
    brand_id             INT                                                NOT NULL,
    CONSTRAINT fk_brand_id
        FOREIGN KEY (brand_id)
            REFERENCES car_shop.brands (brand_id),
    CONSTRAINT fk_colour
        FOREIGN KEY (colour_id)
            REFERENCES car_shop.colours (colour_id)
);
-- Создадим таблицу sales
DROP TABLE IF EXISTS car_shop.sales CASCADE;
CREATE TABLE car_shop.sales
(
    sale_id      SERIAL PRIMARY KEY      NOT NULL,
    client_id    INT                     NOT NULL,
    model_id     INT                     NOT NULL,
    date_of_sale DATE                    NOT NULL,
    price        DECIMAL(9, 2)           NOT NULL, -- ограничим цену до 9999999.99
    discount     DECIMAL(4, 2) DEFAULT 0 NOT NULL, -- ограничим скидку до 99.99, если попадётся NULL то вставляем 0.
    CONSTRAINT fk_client_id
        FOREIGN KEY (client_id)
            REFERENCES car_shop.clients (client_id),
    CONSTRAINT fk_model_id
        FOREIGN KEY (model_id)
            REFERENCES car_shop.car_models (model_id)
);
-- Заполним таблицу clients
INSERT INTO car_shop.clients (name, last_name, phone)
SELECT DISTINCT SPLIT_PART(person, ' ', 1),
                SPLIT_PART(person, ' ', 2),
                phone
FROM raw_data.sales;
-- Проверим количество строк в таблице CLIENTS
SELECT COUNT(*)
FROM car_shop.clients;
-- Оказывается в таблице были люди которые купили несколько автомобилей.
-- Заполним таблицу countries
INSERT INTO car_shop.countries (country_name)
SELECT DISTINCT brand_origin
FROM raw_data.sales;
-- Проверим количество строк и страны в таблице countries
SELECT COUNT(*)
FROM car_shop.countries;
SELECT *
from car_shop.countries;
-- Заполним таблицу brands
TRUNCATE TABLE car_shop.brands CASCADE;
INSERT INTO car_shop.brands (brand_name, country_id)
SELECT DISTINCT TRIM(SPLIT_PART(auto, ' ', 1)),
                CASE
                    WHEN brand_origin = 'Russia' THEN 1
                    WHEN brand_origin = 'South Korea' THEN 2
                    WHEN brand_origin = 'USA' THEN 3
                    WHEN brand_origin = 'Germany' THEN 4
                    ELSE 5 END
FROM raw_data.sales;
-- Проверим что получилось
SELECT *
from car_shop.brands;
-- Заполним таблицу colours
TRUNCATE TABLE car_shop.colours CASCADE;
INSERT INTO car_shop.colours (colour)
SELECT DISTINCT SPLIT_PART(auto, ', ', 2)
FROM raw_data.sales;
-- Проверим что получилось
SELECT *
FROM car_shop.colours;
-- Заполним таблицу car_models
TRUNCATE TABLE car_shop.car_models CASCADE;
INSERT INTO car_shop.car_models (model_name, gasoline_consumption, colour_id, brand_id)
SELECT DISTINCT TRIM(SPLIT_PART(SUBSTR(auto, STRPOS(auto, ' ')), ',', 1)) AS model_name,
                COALESCE(gasoline_consumption, 0),
                c.colour_id                                               AS colour_id,
                brand_id
FROM raw_data.sales s
         JOIN car_shop.brands b
              ON SPLIT_PART(s.auto, ' ', 1) = b.brand_name
         JOIN car_shop.colours c
              ON SPLIT_PART(s.auto, ', ', 2) = c.colour;
SELECT *
FROM car_shop.car_models;
-- Заполним таблицу sales
TRUNCATE TABLE car_shop.sales CASCADE;
INSERT INTO car_shop.sales (client_id, model_id, date_of_sale, price, discount)
SELECT c.client_id,
       m.model_id,
       date,
       price,
       discount
FROM raw_data.sales s
         JOIN car_shop.clients c
              ON SPLIT_PART(s.person, ' ', 1) = c.name
                  AND SPLIT_PART(s.person, ' ', 2) = c.last_name
                  AND s.phone = c.phone
         JOIN car_shop.car_models m
              ON TRIM(SPLIT_PART(SUBSTR(s.auto, STRPOS(s.auto, ' ')), ',', 1)) = m.model_name
         JOIN car_shop.colours c2 on c2.colour_id = m.colour_id;
SELECT *
FROM car_shop.sales;
-- Аналитические запросы
-- 1. Напишите запрос, который выведет процент моделей машин, у которых нет
-- параметра gasoline_consumption.
SELECT ROUND(SUM(CASE WHEN gasoline_consumption = 0 THEN 1.0 ELSE 0.0 END) / COUNT(*) * 100, 2) AS percent
FROM car_shop.car_models;
-- 2. Напишите запрос, который покажет название бренда и среднюю цену его
-- автомобилей в разбивке по всем годам с учётом скидки. Итоговый результат
-- отсортируйте по названию бренда и году в восходящем порядке. Среднюю цену
-- округлите до второго знака после запятой.
SELECT b.brand_name,
       EXTRACT(YEAR FROM s.date_of_sale)               AS year,
       ROUND(AVG(s.price * (1 - s.discount / 100)), 2) AS avg_price
FROM car_shop.sales s
         JOIN car_shop.car_models m
              ON s.model_id = m.model_id
         JOIN car_shop.brands b
              ON m.brand_id = b.brand_id
GROUP BY b.brand_name, year
ORDER BY b.brand_name, year;
-- 3. Посчитайте среднюю цену всех автомобилей с разбивкой по месяцам в 2022
-- году с учётом скидки. Результат отсортируйте по месяцам в восходящем порядке.
-- Среднюю цену округлите до второго знака после запятой.
SELECT EXTRACT(MONTH FROM s.date_of_sale)              AS month,
       EXTRACT(YEAR FROM s.date_of_sale)               AS year,
       ROUND(AVG(s.price * (1 - s.discount / 100)), 2) AS avg_price
FROM car_shop.sales s
WHERE EXTRACT(YEAR FROM s.date_of_sale) = 2022
GROUP BY month, year
ORDER BY month;
-- 4. Используя функцию STRING_AGG, напишите запрос, который выведет список купленных
-- машин у каждого пользователя через запятую. Пользователь может купить две одинаковые
-- машины — это нормально. Название машины покажите полное, с названием бренда — например:
-- Tesla Model 3. Отсортируйте по имени пользователя в восходящем порядке. Сортировка
-- внутри самой строки с машинами не нужна.
SELECT CONCAT(c.name, ' ', c.last_name)                          AS client_name,
       STRING_AGG(CONCAT(b.brand_name, ' ', m.model_name), ', ') AS cars
FROM car_shop.sales s
         JOIN car_shop.clients c
              ON s.client_id = c.client_id
         JOIN car_shop.car_models m
              ON s.model_id = m.model_id
         JOIN car_shop.brands b
              ON m.brand_id = b.brand_id
GROUP BY CONCAT(c.name, ' ', c.last_name)
ORDER BY CONCAT(c.name, ' ', c.last_name);
-- 5. Напишите запрос, который вернёт самую большую и самую маленькую цену продажи автомобиля
-- с разбивкой по стране без учёта скидки. Цена в колонке price дана с учётом скидки.
SELECT c.country_name,
       MAX(s.price) AS max_price,
       MIN(s.price) AS min_price
FROM car_shop.sales s
         JOIN car_shop.car_models m
              ON s.model_id = m.model_id
         JOIN car_shop.brands b
              ON m.brand_id = b.brand_id
         JOIN car_shop.countries c
              ON b.country_id = c.country_id
GROUP BY c.country_name;
-- 6. Напишите запрос, который покажет количество всех пользователей из США. Это пользователи,
-- у которых номер телефона начинается на +1.
SELECT *
FROM car_shop.clients
WHERE phone LIKE '+1%'
   OR phone LIKE '001%';