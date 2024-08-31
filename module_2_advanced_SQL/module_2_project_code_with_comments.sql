/* Во втором самостоятельном проекте вы построите дополнительные таблицы с продвинутыми
   типами данных и выполните семь заданий: поработаете с геоданными, создадите представления
   и напишете несколько аналитических запросов, используя оконные функции и подзапросы. */

/* Этап 1. Создание дополнительных таблиц
Сперва создайте дополнительные таблицы с продвинутыми типами данных.
Вот пошаговая инструкция:

Шаг 1. Cоздайте enum cafe.restaurant_type с типом заведения coffee_shop, restaurant, bar,
       pizzeria. Используйте этот тип данных при создании таблицы restaurants. */

CREATE TYPE cafe.restaurant_type AS ENUM ('coffee_shop', 'restaurant', 'bar', 'pizzeria');

/* Шаг 2. Создайте таблицу cafe.restaurants с информацией о ресторанах. В качестве первичного
       ключа используйте случайно сгенерированный uuid. Таблица хранит: restaurant_uuid,
       название заведения, его локацию в формате PostGIS, тип кафе и меню. */

DROP TABLE cafe.restaurants CASCADE;

CREATE TABLE cafe.restaurants
(
    restaurant_uuid UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(255)           NOT NULL,
    location        GEOGRAPHY(POINT, 4326) NOT NULL, -- PostGIS location
    type            cafe.restaurant_type   NOT NULL,
    menu            JSONB
);

TRUNCATE TABLE cafe.restaurants CASCADE;

INSERT INTO cafe.restaurants (restaurant_uuid, name, location, type, menu)
SELECT gen_random_uuid()                                                                             AS restaurant_uuid,
       distinct_restaurants.cafe_name                                                                AS name,
       ST_SetSRID(ST_MakePoint(distinct_restaurants.longitude, distinct_restaurants.latitude), 4326) AS location,
       distinct_restaurants.type::cafe.restaurant_type,
       m.menu
FROM (SELECT DISTINCT s.cafe_name,
                      s.longitude,
                      s.latitude,
                      s.type
      FROM raw_data.sales s) AS distinct_restaurants
         JOIN raw_data.menu m ON distinct_restaurants.cafe_name = m.cafe_name;

SELECT count(*)
FROM cafe.restaurants
LIMIT 10;

/* Шаг 3. Создайте таблицу cafe.managers с информацией о менеджерах. В качестве первичного
       ключа используйте случайно сгенерированный uuid. Таблица хранит: manager_uuid, имя
       менеджера и его телефон. */

DROP TABLE cafe.managers CASCADE;

CREATE TABLE cafe.managers
(
    manager_uuid UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name         VARCHAR(255) NOT NULL,
    phone        VARCHAR(20)  NOT NULL
);

TRUNCATE TABLE cafe.managers CASCADE;

INSERT INTO cafe.managers (manager_uuid, name, phone)
SELECT gen_random_uuid()               AS manager_uuid,
       distinct_managers.manager       AS name,
       distinct_managers.manager_phone AS phone
FROM (SELECT DISTINCT manager, manager_phone
      FROM raw_data.sales) AS distinct_managers;

SELECT count(*)
FROM cafe.managers
LIMIT 10;

/* Шаг 4. Создайте таблицу cafe.restaurant_manager_work_dates. Таблица хранит: restaurant_uuid,
       manager_uuid, дату начала работы в ресторане и дату окончания работы в ресторане.
       Задайте составной первичный ключ из двух полей: restaurant_uuid и manager_uuid.
       Работа менеджера в ресторане от даты начала до даты окончания — единый период,
       без перерывов. */

DROP TABLE cafe.restaurant_manager_work_dates CASCADE;

CREATE TABLE cafe.restaurant_manager_work_dates
(
    restaurant_uuid UUID NOT NULL,
    manager_uuid    UUID NOT NULL,
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL,
    PRIMARY KEY (restaurant_uuid, manager_uuid),
    FOREIGN KEY (restaurant_uuid) REFERENCES cafe.restaurants (restaurant_uuid),
    FOREIGN KEY (manager_uuid) REFERENCES cafe.managers (manager_uuid)
);

TRUNCATE TABLE cafe.restaurant_manager_work_dates CASCADE;

INSERT INTO cafe.restaurant_manager_work_dates (restaurant_uuid, manager_uuid, start_date, end_date)
SELECT r.restaurant_uuid,
       m.manager_uuid,
       MIN(s.report_date) AS start_date,
       MAX(s.report_date) AS end_date
FROM raw_data.sales s
         JOIN
     cafe.restaurants r ON s.cafe_name = r.name
         JOIN
     cafe.managers m ON s.manager = m.name AND s.manager_phone = m.phone
GROUP BY r.restaurant_uuid, m.manager_uuid;

SELECT count(*)
FROM cafe.restaurant_manager_work_dates;

/* Шаг 5. Создайте таблицу cafe.sales со столбцами: date, restaurant_uuid, avg_check. Задайте
       составной первичный ключ из даты и uuid ресторана. */

DROP TABLE cafe.sales CASCADE;

CREATE TABLE cafe.sales
(
    date            DATE           NOT NULL,
    restaurant_uuid UUID           NOT NULL,
    avg_check       DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (date, restaurant_uuid),
    FOREIGN KEY (restaurant_uuid) REFERENCES cafe.restaurants (restaurant_uuid)
);

TRUNCATE TABLE cafe.sales CASCADE;

INSERT INTO cafe.sales (date, restaurant_uuid, avg_check)
SELECT s.report_date,
       r.restaurant_uuid,
       s.avg_check
FROM raw_data.sales AS s
         JOIN
     cafe.restaurants AS r ON s.cafe_name = r.name;

SELECT count(*)
FROM cafe.sales;

/* Этап 2. Создание представлений и написание аналитических запросов
Дополнительные таблицы готовы, теперь — пора представлений и запросов.

Задание 1
Чтобы выдать премию менеджерам, нужно понять, у каких заведений самый высокий средний чек.
Создайте представление, которое покажет топ-3 заведений внутри каждого типа заведения по
среднему чеку за все даты. Столбец со средним чеком округлите до второго знака после
запятой. */

CREATE VIEW cafe.top_3_restaurants_by_type AS
WITH ranked_restaurants AS (SELECT r.type,
                                   r.name,
                                   r.restaurant_uuid,
                                   ROUND(AVG(s.avg_check), 2)                                             AS avg_check,
                                   ROW_NUMBER() OVER (PARTITION BY r.type ORDER BY AVG(s.avg_check) DESC) AS rank
                            FROM cafe.restaurants r
                                     JOIN
                                 cafe.sales s ON r.restaurant_uuid = s.restaurant_uuid
                            GROUP BY r.type, r.name, r.restaurant_uuid)
SELECT type,
       name,
       restaurant_uuid,
       avg_check
FROM ranked_restaurants
WHERE rank <= 3;

/*Задание 2
Создайте материализованное представление, которое покажет, как изменяется средний чек для
каждого заведения от года к году за все года за исключением 2023 года. Все столбцы со
средним чеком округлите до второго знака после запятой.

Вот формат материализованного представления, числа и названия — для наглядности:
Год	    Название заведения	Тип заведения	Средний чек в этом году	Средний чек в предыдущем году	Изменение среднего чека в %
2017	Заведение 1	        Кофейня	        655.25	                [null]	                        [null]
2018	Заведение 1	        Кофейня	6       56.22	                655.25	                        0.15 */

CREATE MATERIALIZED VIEW cafe.yearly_avg_check_changes AS
WITH yearly_checks AS (SELECT EXTRACT(YEAR FROM s.date)  AS year,
                              r.name                     AS restaurant_name,
                              r.type                     AS restaurant_type,
                              ROUND(AVG(s.avg_check), 2) AS avg_check
                       FROM cafe.sales s
                                JOIN
                            cafe.restaurants r ON s.restaurant_uuid = r.restaurant_uuid
                       WHERE EXTRACT(YEAR FROM s.date) != 2023
                       GROUP BY year, r.name, r.type),
     yearly_checks_with_lag AS (SELECT yc.year,
                                       yc.restaurant_name,
                                       yc.restaurant_type,
                                       yc.avg_check                                            AS current_year_avg_check,
                                       LAG(yc.avg_check, 1)
                                       OVER (PARTITION BY yc.restaurant_name ORDER BY yc.year) AS previous_year_avg_check
                                FROM yearly_checks yc)
SELECT year,
       restaurant_name,
       restaurant_type,
       current_year_avg_check,
       previous_year_avg_check,
       ROUND(
               CASE
                   WHEN previous_year_avg_check IS NULL THEN NULL
                   ELSE (current_year_avg_check - previous_year_avg_check) * 100.0 / previous_year_avg_check
                   END, 2
       ) AS avg_check_change_percentage
FROM yearly_checks_with_lag;

/* Задание 3
Найдите топ-3 заведения, где чаще всего менялся менеджер за весь период.
Вот формат итоговой таблицы, числа и названия — для наглядности:
Название заведения	Сколько раз менялся менеджер
Заведение 1	        6
Заведение 2	        5
Заведение 3	        5 */

SELECT r.name                           AS restaurant_name,
       r.type                           AS restaurant_type,
       COUNT(DISTINCT rmw.manager_uuid) AS manager_change_count
FROM cafe.restaurants r
         JOIN
     cafe.restaurant_manager_work_dates rmw ON r.restaurant_uuid = rmw.restaurant_uuid
GROUP BY r.name, r.type
ORDER BY manager_change_count DESC
LIMIT 3;

/* Найдите пиццерию с самым большим количеством пицц в меню. Если таких пиццерий несколько,
выведите все.

Вот формат итоговой таблицы, числа и названия — для наглядности:
Название заведения	Количество пицц в меню
Заведение 1	        10
Заведение 2	        10
Заведение 3	        10 */

WITH pizzeria_counts AS (SELECT r.name  AS restaurant_name,
                                r.type  AS restaurant_type,
                                CASE
                                    WHEN jsonb_typeof(r.menu -> 'Пицца') = 'array'
                                        THEN jsonb_array_length(r.menu -> 'Пицца')
                                    WHEN jsonb_typeof(r.menu -> 'Пицца') = 'object' THEN (SELECT COUNT(*)
                                                                                          FROM jsonb_each(r.menu -> 'Пицца'))
                                    ELSE 0
                                    END AS pizza_count
                         FROM cafe.restaurants r
                         WHERE r.type = 'pizzeria'),
     max_pizza_count AS (SELECT MAX(pizza_count) AS max_count
                         FROM pizzeria_counts)
SELECT pc.restaurant_name,
       pc.pizza_count
FROM pizzeria_counts pc
         JOIN
     max_pizza_count mpc ON pc.pizza_count = mpc.max_count;

/* Задание 5
Найдите самую дорогую пиццу для каждой пиццерии.
Вот формат итоговой таблицы, числа и названия — для наглядности:
Название заведения	Тип блюда	Название пиццы	Цена
Заведение 1	        Пицца	    Маргарита	    689
Заведение 2	        Пицца	    Диавола	        566
Заведение 3	        Пицца	    Четыре сезона	455 */

WITH menu_cte AS (SELECT r.name           AS restaurant_name,
                         'Пицца'          AS dish_type,
                         m.key            AS pizza_name,
                         m.value::integer AS price
                  FROM cafe.restaurants r,
                       LATERAL jsonb_each_text(r.menu -> 'Пицца') AS m(key, value)
                  WHERE r.type = 'pizzeria'),
     menu_with_rank AS (SELECT restaurant_name,
                               dish_type,
                               pizza_name,
                               price,
                               ROW_NUMBER() OVER (PARTITION BY restaurant_name ORDER BY price DESC) AS rank
                        FROM menu_cte)
SELECT restaurant_name,
       dish_type,
       pizza_name,
       price
FROM menu_with_rank
WHERE rank = 1
ORDER BY price DESC, restaurant_name;

/* Задание 6
   Найдите два самых близких друг к другу заведения одного типа.
   Вот формат итоговой таблицы, числа и названия — для наглядности:
Название Заведения 1	Название Заведения 2	Тип заведения	Расстояние
Мир Эспрессо	        Кофеинозависимые	    Кофейня	        63.67510564 */

WITH distances AS (SELECT r1.name                               AS restaurant1_name,
                          r2.name                               AS restaurant2_name,
                          r1.type                               AS restaurant_type,
                          ST_Distance(r1.location, r2.location) AS distance
                   FROM cafe.restaurants r1
                            JOIN
                        cafe.restaurants r2
                        ON
                            r1.restaurant_uuid <> r2.restaurant_uuid
                                AND r1.type = r2.type),
     ranked_distances AS (SELECT restaurant1_name,
                                 restaurant2_name,
                                 restaurant_type,
                                 distance,
                                 ROW_NUMBER() OVER (PARTITION BY restaurant_type ORDER BY distance) AS rank
                          FROM distances)
SELECT restaurant1_name,
       restaurant2_name,
       restaurant_type,
       distance
FROM ranked_distances
WHERE rank = 1
ORDER BY restaurant_type;

/* Задание 7
   Найдите район с самым большим количеством заведений и район с самым маленьким количеством
   заведений. Первой строчкой выведите район с самым большим количеством заведений,
   второй — с самым маленьким.
   Вот формат итоговой таблицы, числа и названия — для наглядности:
Название района	                                Количество заведений
Район с самым большим количеством заведений	    15
Район с самым маленьким количеством заведений	2 */

WITH restaurant_districts AS (SELECT r.name AS restaurant_name,
                                     d.district_name
                              FROM cafe.restaurants r
                                       JOIN
                                   cafe.districts d
                                   ON
                                       ST_Contains(d.district_geom, r.location::geometry)),
     district_counts AS (SELECT district_name,
                                COUNT(*) AS number_of_restaurants
                         FROM restaurant_districts
                         GROUP BY district_name),
     max_district AS (SELECT district_name,
                             number_of_restaurants
                      FROM district_counts
                      ORDER BY number_of_restaurants DESC
                      LIMIT 1),
     min_district AS (SELECT district_name,
                             number_of_restaurants
                      FROM district_counts
                      ORDER BY number_of_restaurants ASC
                      LIMIT 1)
SELECT district_name,
       number_of_restaurants
FROM max_district
UNION ALL
SELECT district_name,
       number_of_restaurants
FROM min_district;




