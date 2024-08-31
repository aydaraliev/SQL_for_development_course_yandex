/* Вторая часть проекта — оптимизация запросов
Для выполнения заданий второй части разверните этот дамп базы данных:
project_4_part2.sql
В файле ниже — пользовательские скрипты, которые выполняются на базе данных. Выполните их на своём
компьютере. Проверьте, что в вашей СУБД включён модуль pg_stat_statements — это обязательное условие.
Вспомнить, как подключить модуль можно в третьем уроке третьей темы.
Файл со скриптами:
user_scripts_pr4.sql
Ваша задача — найти пять самых медленных скриптов и оптимизировать их. Важно: при оптимизации в этой
части проекта нельзя менять структуру БД. */

/* В решении укажите способ, которым вы искали медленные запросы, а также для каждого из пяти
запросов:
    Составьте план запроса до оптимизации.
    Укажите общее время выполнения скрипта до оптимизации (вы можете взять его из параметра
     actual time в плане запроса).
    Отметьте узлы с высокой стоимостью и опишите, как их можно оптимизировать.
    Напишите и вложите в решение все необходимые скрипты для оптимизации запроса.
    Составьте план оптимизированного запроса.
    Опишите, что изменилось в плане запроса после оптимизации.
    Укажите общее время выполнения запроса после оптимизации. */

-- Установим расширение для поиска медленных запросов
-- CREATE EXTENSION pg_stat_statements;

-- Прогоним предоставленный скрипт с запросами.
SELECT pg_stat_statements_reset();

-- 1
-- вычисляет среднюю стоимость блюда в определенном ресторане
SELECT avg(dp.price)
FROM dishes_prices dp
         JOIN dishes d ON dp.dishes_id = d.object_id
WHERE d.rest_id LIKE '%14ce5c408d2142f6bd5b7afad906bc7e%'
  AND dp.date_begin::date <= current_date
  AND (dp.date_end::date >= current_date
    OR dp.date_end IS NULL);

-- 2
-- выводит данные о конкретном заказе: id, дату, стоимость и текущий статус
SELECT o.order_id, o.order_dt, o.final_cost, s.status_name
FROM order_statuses os
         JOIN orders o ON o.order_id = os.order_id
         JOIN statuses s ON s.status_id = os.status_id
WHERE o.user_id = 'c2885b45-dddd-4df3-b9b3-2cc012df727c'::uuid
  AND os.status_dt IN (SELECT max(status_dt)
                       FROM order_statuses
                       WHERE order_id = o.order_id);

-- 3
-- выводит id и имена пользователей, фамилии которых входят в список
SELECT u.user_id, u.first_name
FROM users u
WHERE u.last_name IN
      ('КЕДРИНА', 'АДОА', 'АКСЕНОВА', 'АЙМАРДАНОВА', 'БОРЗЕНКОВА', 'ГРИПЕНКО', 'ГУЦА', 'ЯВОРЧУКА', 'ХВИЛИНА', 'ШЕЙНОГА',
       'ХАМЧИЧЕВА', 'БУХТУЕВА', 'МАЛАХОВЦЕВА', 'КРИСС', 'АЧАСОВА', 'ИЛЛАРИОНОВА', 'ЖЕЛЯБИНА', 'СВЕТОЗАРОВА', 'ИНЖИНОВА',
       'СЕРДЮКОВА', 'ДАНСКИХА')
ORDER BY 1 DESC;

-- 4
-- ищет все салаты в списке блюд
SELECT d.object_id, d.name
FROM dishes d
WHERE d.name LIKE 'salat%';

-- 5
-- определяет максимальную и минимальную сумму заказа по городу
SELECT max(p.payment_sum) max_payment, min(p.payment_sum) min_payment
FROM payments p
         JOIN orders o ON o.order_id = p.order_id
WHERE o.city_id = 2;

-- 6
-- ищет всех партнеров определенного типа в определенном городе
SELECT p.id partner_id, p.chain partner_name
FROM partners p
         JOIN cities c ON c.city_id = p.city_id
WHERE p.type = 'Пекарня'
  AND c.city_name = 'Владивосток';

-- 7
-- ищет действия и время действия определенного посетителя
SELECT event, datetime
FROM user_logs
WHERE visitor_uuid = 'fd3a4daa-494a-423a-a9d1-03fd4a7f94e0'
ORDER BY 2;

-- 8
-- ищет логи за текущий день
SELECT *
FROM user_logs
WHERE datetime::date > current_date;

-- 9
-- определяет количество неоплаченных заказов
SELECT count(*)
FROM order_statuses os
         JOIN orders o ON o.order_id = os.order_id
WHERE (SELECT count(*)
       FROM order_statuses os1
       WHERE os1.order_id = o.order_id
         AND os1.status_id = 2) = 0
  AND o.city_id = 1;

-- 10
-- определяет долю блюд дороже 1000
SELECT (SELECT count(*)
        FROM dishes_prices dp
        WHERE dp.date_end IS NULL
          AND dp.price > 1000.00)::NUMERIC / count(*)::NUMERIC
FROM dishes_prices
WHERE date_end IS NULL;

-- 11
-- отбирает пользователей определенного города, чей день рождения находится в интервале +- 3 дня от текущей даты
SELECT user_id, current_date - birth_date
FROM users
WHERE city_id = 1
  AND birth_date >= current_date - 3
  AND birth_date <= current_date + 3;

-- 12
-- вычисляет среднюю стоимость блюд разных категорий
SELECT 'average price with fish', avg(dp.price)
FROM dishes_prices dp
         JOIN dishes d ON d.object_id = dp.dishes_id
WHERE dp.date_end IS NULL
  AND d.fish = 1
UNION
SELECT 'average price with meat', avg(dp.price)
FROM dishes_prices dp
         JOIN dishes d ON d.object_id = dp.dishes_id
WHERE dp.date_end IS NULL
  AND d.meat = 1
UNION
SELECT 'average price of spicy food', avg(dp.price)
FROM dishes_prices dp
         JOIN dishes d ON d.object_id = dp.dishes_id
WHERE dp.date_end IS NULL
  AND d.spicy = 1
ORDER BY 2;

-- 13
-- ранжирует города по общим продажам за определенный период
SELECT ROW_NUMBER() OVER ( ORDER BY sum(o.final_cost) DESC),
       c.city_name,
       sum(o.final_cost)
FROM cities c
         JOIN orders o ON o.city_id = c.city_id
WHERE order_dt >= to_timestamp('01.01.2021 00-00-00', 'dd.mm.yyyy hh24-mi-ss')
  AND order_dt < to_timestamp('02.01.2021', 'dd.mm.yyyy hh24-mi-ss')
GROUP BY c.city_name;

-- 14
-- вычисляет количество заказов определенного пользователя
SELECT COUNT(*)
FROM orders
WHERE user_id = '0fd37c93-5931-4754-a33b-464890c22689';

-- 15
-- вычисляет количество заказов позиций, продажи которых выше среднего
SELECT d.name, SUM(count) AS orders_quantity
FROM order_items oi
         JOIN dishes d ON d.object_id = oi.item
WHERE oi.item IN (SELECT item
                  FROM (SELECT item, SUM(count) AS total_sales
                        FROM order_items oi
                        GROUP BY 1) dishes_sales
                  WHERE dishes_sales.total_sales > (SELECT SUM(t.total_sales) / COUNT(*)
                                                    FROM (SELECT item, SUM(count) AS total_sales
                                                          FROM order_items oi
                                                          GROUP BY 1) t))
GROUP BY 1
ORDER BY orders_quantity DESC;

-- Найдём 5 самых медленных запросов.
SELECT oid, datname
FROM pg_database;

SELECT query,
       calls,
       total_exec_time,
       min_exec_time,
       max_exec_time,
       mean_exec_time,
       rows
FROM pg_stat_statements
WHERE dbid = 17415
ORDER BY total_exec_time DESC;

-- Топ 5 самых медленных запросов
-- 9, 8, 7, 2, 15

-- Начнём с запроса 9 (самый медленный).
-- определяет количество неоплаченных заказов
EXPLAIN ANALYZE
SELECT count(*)
FROM order_statuses os
         JOIN orders o ON o.order_id = os.order_id
WHERE (SELECT count(*)
       FROM order_statuses os1
       WHERE os1.order_id = o.order_id
         AND os1.status_id = 2) = 0
  AND o.city_id = 1;

/* План запроса
 Aggregate  (cost=61369943.01..61369943.02 rows=1 width=8) (actual time=13891.931..13891.932 rows=1 loops=1)
  ->  Nested Loop  (cost=0.30..61369942.79 rows=90 width=0) (actual time=101.254..13891.740 rows=1190 loops=1)
        ->  Seq Scan on order_statuses os  (cost=0.00..2059.34 rows=124334 width=8) (actual time=0.005..6.030 rows=124334 loops=1)
        ->  Memoize  (cost=0.30..2681.36 rows=1 width=8) (actual time=0.112..0.112 rows=0 loops=124334)
              Cache Key: os.order_id
              Cache Mode: logical
              Hits: 96650  Misses: 27684  Evictions: 0  Overflows: 0  Memory Usage: 1994kB
              ->  Index Scan using orders_order_id_idx on orders o  (cost=0.29..2681.35 rows=1 width=8) (actual time=0.497..0.497 rows=0 loops=27684)
                    Index Cond: (order_id = os.order_id)
                    Filter: ((city_id = 1) AND ((SubPlan 1) = 0))
                    Rows Removed by Filter: 1
                    SubPlan 1
                      ->  Aggregate  (cost=2681.01..2681.02 rows=1 width=8) (actual time=3.471..3.471 rows=1 loops=3958)
                            ->  Seq Scan on order_statuses os1  (cost=0.00..2681.01 rows=1 width=0) (actual time=2.215..3.469 rows=1 loops=3958)
                                  Filter: ((order_id = o.order_id) AND (status_id = 2))
                                  Rows Removed by Filter: 124333
Planning Time: 0.171 ms
JIT:
  Functions: 19
"  Options: Inlining true, Optimization true, Expressions true, Deforming true"
"  Timing: Generation 0.744 ms, Inlining 6.784 ms, Optimization 43.575 ms, Emission 29.790 ms, Total 80.893 ms"
Execution Time: 13892.963 ms
 */

-- Общее время исполнения до оптимизации 13891.932 мс.
-- В первую очередь бросаются в глаза 2 Seq Scan в плане запроса, их можно ускорить создав индексы.
-- Конкретнее необходимо создать индексы для столбцов order_id и status_id таблицы order_statuses,
-- а также для столбца city_id таблицы orders.
-- Кроме того у нас коррелирующий подзапрос который выполняется для каждой строки таблицы orders.
-- Это можно решить конструкцией NOT EXISTS.

-- Сначала создадим индексы
CREATE INDEX idx_order_statuses_order_id_status_id ON order_statuses (order_id, status_id);
CREATE INDEX idx_orders_city_id ON orders (city_id);
-- Запрос уже начал работать заметно быстрее.

-- Перепишем запрос используя NOT EXISTS
EXPLAIN ANALYZE
SELECT count(*)
FROM orders o
WHERE o.city_id = 1
  AND NOT EXISTS (SELECT 1
                  FROM order_statuses os
                  WHERE os.order_id = o.order_id
                    AND os.status_id = 2);

/* План поправленного запроса
Aggregate  (cost=2939.88..2939.89 rows=1 width=8) (actual time=5.654..5.656 rows=1 loops=1)
  ->  Hash Right Anti Join  (cost=465.91..2936.94 rows=1174 width=0) (actual time=5.544..5.624 rows=1190 loops=1)
        Hash Cond: (os.order_id = o.order_id)
        ->  Seq Scan on order_statuses os  (cost=0.00..2370.18 rows=19471 width=8) (actual time=0.005..3.692 rows=19330 loops=1)
              Filter: (status_id = 2)
              Rows Removed by Filter: 105004
        ->  Hash  (cost=416.44..416.44 rows=3958 width=8) (actual time=0.911..0.911 rows=3958 loops=1)
              Buckets: 4096  Batches: 1  Memory Usage: 187kB
              ->  Bitmap Heap Scan on orders o  (cost=46.96..416.44 rows=3958 width=8) (actual time=0.089..0.664 rows=3958 loops=1)
                    Recheck Cond: (city_id = 1)
                    Heap Blocks: exact=314
                    ->  Bitmap Index Scan on idx_orders_city_id  (cost=0.00..45.97 rows=3958 width=0) (actual time=0.062..0.063 rows=3958 loops=1)
                          Index Cond: (city_id = 1)
Planning Time: 0.125 ms
Execution Time: 5.684 ms */

-- Сравнивая план запроса с планом не оптимизированного запроса время выполнения запроса стало
-- 5.656 против 13891.932. Цель увеличить производительность в несколько тысяч раз достигнута.
-- Сам запрос достаточно сильно поменялся, остался только один Seq Scan, во всех остальных местах
-- используются индексы. Оставшийся Seq Scan похоже вынужденная мера, потому что надо сделать проход
-- по большинству строк в таблице.

-- Перейдём к запросу 8
-- ищет логи за текущий день
EXPLAIN ANALYZE
SELECT *
FROM user_logs
WHERE datetime::date > current_date;

/*
Append  (cost=0.00..156002.50 rows=1550896 width=83) (actual time=257.813..257.815 rows=0 loops=1)
  ->  Seq Scan on user_logs user_logs_1  (cost=0.00..39193.25 rows=410081 width=83) (actual time=70.334..70.334 rows=0 loops=1)
        Filter: ((datetime)::date > CURRENT_DATE)
        Rows Removed by Filter: 1230243
  ->  Seq Scan on user_logs_y2021q2 user_logs_2  (cost=0.00..108215.68 rows=1132337 width=83) (actual time=186.462..186.463 rows=0 loops=1)
        Filter: ((datetime)::date > CURRENT_DATE)
        Rows Removed by Filter: 3397415
  ->  Seq Scan on user_logs_y2021q3 user_logs_3  (cost=0.00..826.82 rows=8435 width=83) (actual time=1.011..1.011 rows=0 loops=1)
        Filter: ((datetime)::date > CURRENT_DATE)
        Rows Removed by Filter: 25304
  ->  Seq Scan on user_logs_y2021q4 user_logs_4  (cost=0.00..12.28 rows=43 width=584) (actual time=0.002..0.002 rows=0 loops=1)
        Filter: ((datetime)::date > CURRENT_DATE)
Planning Time: 0.141 ms
JIT:
  Functions: 8
"  Options: Inlining false, Optimization false, Expressions true, Deforming true"
"  Timing: Generation 0.445 ms, Inlining 0.000 ms, Optimization 0.271 ms, Emission 2.842 ms, Total 3.559 ms"
Execution Time: 258.311 ms */

-- Общее время выполнения запроса 257.815 мс.
-- На родительской и дочерних таблицах user_logs используется Seq Scan, дороже всего обходится
-- таблица user_logs_y2021q2. Для решения проблемы перепишем запрос, необходимо убрать каст типа
-- данных date на столбец datetime, это должно помочь начать индексам по столбцу datetime работать.

-- Переписанный запрос
EXPLAIN ANALYZE
SELECT *
FROM user_logs
WHERE datetime >= current_date::timestamp;

/*
Append  (cost=0.43..37.71 rows=46 width=551) (actual time=0.007..0.007 rows=0 loops=1)
  ->  Index Scan using user_logs_datetime_idx on user_logs user_logs_1  (cost=0.43..8.45 rows=1 width=83) (actual time=0.003..0.003 rows=0 loops=1)
        Index Cond: (datetime >= (CURRENT_DATE)::timestamp without time zone)
  ->  Index Scan using user_logs_y2021q2_datetime_idx on user_logs_y2021q2 user_logs_2  (cost=0.43..8.45 rows=1 width=83) (actual time=0.001..0.001 rows=0 loops=1)
        Index Cond: (datetime >= (CURRENT_DATE)::timestamp without time zone)
  ->  Index Scan using user_logs_y2021q3_datetime_idx on user_logs_y2021q3 user_logs_3  (cost=0.29..8.30 rows=1 width=83) (actual time=0.001..0.001 rows=0 loops=1)
        Index Cond: (datetime >= (CURRENT_DATE)::timestamp without time zone)
  ->  Seq Scan on user_logs_y2021q4 user_logs_4  (cost=0.00..12.28 rows=43 width=584) (actual time=0.001..0.001 rows=0 loops=1)
        Filter: (datetime >= (CURRENT_DATE)::timestamp without time zone)
Planning Time: 0.138 ms
Execution Time: 0.019 ms
 */

-- Время выполнения запроса упало с 257.815 до 0.007 секунд, таким образом цель уменьшить время
-- выполнение в несколько тысяч раз достигнута. Скорость увеличена за счёт отказа использования
-- каста типа данных date на столбец datetime что позволило использовать существующие индексы. Для
-- дочерней таблицы постгре всё равно решил использовать Seq Scan, возможно из-за малого количества
-- строк.

-- Запрос 7
-- ищет действия и время действия определенного посетителя
EXPLAIN ANALYZE
SELECT event, datetime
FROM user_logs
WHERE visitor_uuid = 'fd3a4daa-494a-423a-a9d1-03fd4a7f94e0'
ORDER BY 2;

/*
 Gather Merge  (cost=92117.14..92140.47 rows=200 width=19) (actual time=74.585..77.522 rows=10 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  ->  Sort  (cost=91117.11..91117.36 rows=100 width=19) (actual time=66.829..66.831 rows=3 loops=3)
        Sort Key: user_logs.datetime
        Sort Method: quicksort  Memory: 25kB
        Worker 0:  Sort Method: quicksort  Memory: 25kB
        Worker 1:  Sort Method: quicksort  Memory: 25kB
        ->  Parallel Append  (cost=0.00..91113.79 rows=100 width=19) (actual time=12.555..66.791 rows=3 loops=3)
              ->  Parallel Seq Scan on user_logs_y2021q2 user_logs_2  (cost=0.00..66460.76 rows=60 width=18) (actual time=21.994..48.377 rows=2 loops=3)
                    Filter: ((visitor_uuid)::text = 'fd3a4daa-494a-423a-a9d1-03fd4a7f94e0'::text)
                    Rows Removed by Filter: 1132470
              ->  Parallel Seq Scan on user_logs user_logs_1  (cost=0.00..24071.52 rows=32 width=18) (actual time=11.473..27.133 rows=2 loops=2)
                    Filter: ((visitor_uuid)::text = 'fd3a4daa-494a-423a-a9d1-03fd4a7f94e0'::text)
                    Rows Removed by Filter: 615119
              ->  Parallel Seq Scan on user_logs_y2021q3 user_logs_3  (cost=0.00..570.06 rows=10 width=18) (actual time=0.962..0.962 rows=0 loops=1)
                    Filter: ((visitor_uuid)::text = 'fd3a4daa-494a-423a-a9d1-03fd4a7f94e0'::text)
                    Rows Removed by Filter: 25304
              ->  Parallel Seq Scan on user_logs_y2021q4 user_logs_4  (cost=0.00..10.96 rows=1 width=282) (actual time=0.001..0.001 rows=0 loops=1)
                    Filter: ((visitor_uuid)::text = 'fd3a4daa-494a-423a-a9d1-03fd4a7f94e0'::text)
Planning Time: 0.102 ms
Execution Time: 77.538 ms
*/

-- Время выполнения запроса 77.522 мс. Дороже всего обходится сортировка по полю datetime, затем
-- идут Seq Scan по основной и дочерним таблицам user_logs. Для решения проблемы необходимо
-- проиндексировать столбцы visitor_uuid и datetime. Важно отметить что необходимо будет так же
-- создать составной индекс по visitor_uuid и datetime одновременно, так как это позволит отбирать
-- uuid и сортировать по datetime за один проход.

CREATE INDEX idx_user_logs_visitor_uuid ON user_logs (visitor_uuid);
CREATE INDEX idx_user_logs_visitor_uuid_datetime ON user_logs (visitor_uuid, datetime);

CREATE INDEX idx_user_logs_y2021q2_visitor_uuid ON user_logs_y2021q2 (visitor_uuid);
CREATE INDEX idx_user_logs_y2021q2_visitor_uuid_datetime ON user_logs_y2021q2 (visitor_uuid, datetime);

CREATE INDEX idx_user_logs_y2021q3_visitor_uuid ON user_logs_y2021q3 (visitor_uuid);
CREATE INDEX idx_user_logs_y2021q3_visitor_uuid_datetime ON user_logs_y2021q3 (visitor_uuid, datetime);

CREATE INDEX idx_user_logs_y2021q4_visitor_uuid ON user_logs_y2021q4 (visitor_uuid);
CREATE INDEX idx_user_logs_y2021q4_visitor_uuid_datetime ON user_logs_y2021q4 (visitor_uuid, datetime);

-- Посмотрим как поменялся план запроса
EXPLAIN ANALYZE
SELECT event, datetime
FROM user_logs
WHERE visitor_uuid = 'fd3a4daa-494a-423a-a9d1-03fd4a7f94e0'
ORDER BY 2;

/*
 Sort  (cost=939.31..939.90 rows=239 width=19) (actual time=0.140..0.141 rows=10 loops=1)
  Sort Key: user_logs.datetime
  Sort Method: quicksort  Memory: 25kB
  ->  Append  (cost=5.02..929.87 rows=239 width=19) (actual time=0.055..0.131 rows=10 loops=1)
        ->  Bitmap Heap Scan on user_logs user_logs_1  (cost=5.02..298.74 rows=77 width=18) (actual time=0.054..0.077 rows=5 loops=1)
              Recheck Cond: ((visitor_uuid)::text = 'fd3a4daa-494a-423a-a9d1-03fd4a7f94e0'::text)
              Heap Blocks: exact=5
              ->  Bitmap Index Scan on idx_user_logs_visitor_uuid_datetime  (cost=0.00..5.00 rows=77 width=0) (actual time=0.042..0.042 rows=5 loops=1)
                    Index Cond: ((visitor_uuid)::text = 'fd3a4daa-494a-423a-a9d1-03fd4a7f94e0'::text)
        ->  Bitmap Heap Scan on user_logs_y2021q2 user_logs_2  (cost=5.55..559.87 rows=144 width=18) (actual time=0.026..0.043 rows=5 loops=1)
              Recheck Cond: ((visitor_uuid)::text = 'fd3a4daa-494a-423a-a9d1-03fd4a7f94e0'::text)
              Heap Blocks: exact=5
              ->  Bitmap Index Scan on idx_user_logs_y2021q2_visitor_uuid  (cost=0.00..5.51 rows=144 width=0) (actual time=0.019..0.019 rows=5 loops=1)
                    Index Cond: ((visitor_uuid)::text = 'fd3a4daa-494a-423a-a9d1-03fd4a7f94e0'::text)
        ->  Bitmap Heap Scan on user_logs_y2021q3 user_logs_3  (cost=4.42..61.90 rows=17 width=18) (actual time=0.008..0.008 rows=0 loops=1)
              Recheck Cond: ((visitor_uuid)::text = 'fd3a4daa-494a-423a-a9d1-03fd4a7f94e0'::text)
              ->  Bitmap Index Scan on idx_user_logs_y2021q3_visitor_uuid  (cost=0.00..4.42 rows=17 width=0) (actual time=0.008..0.008 rows=0 loops=1)
                    Index Cond: ((visitor_uuid)::text = 'fd3a4daa-494a-423a-a9d1-03fd4a7f94e0'::text)
        ->  Index Scan using idx_user_logs_y2021q4_visitor_uuid_datetime on user_logs_y2021q4 user_logs_4  (cost=0.14..8.16 rows=1 width=282) (actual time=0.002..0.002 rows=0 loops=1)
              Index Cond: ((visitor_uuid)::text = 'fd3a4daa-494a-423a-a9d1-03fd4a7f94e0'::text)
Planning Time: 0.537 ms
Execution Time: 0.168 ms
 */

-- Видим что сортировка подешевела на 2 порядка, а также удалось избавиться от Seq Scan. Используемый
-- теперь в большинстве случаев Bitmap Heap Scan и Bitmap Index Scan также работают на несколько
-- порядков лучше. Общее время выполнения запроса составило 0.141 против 77.522, таки образом цель
-- ускорить запрос более чем в 100 раз достигнута.

-- Запрос 2
-- выводит данные о конкретном заказе: id, дату, стоимость и текущий статус
EXPLAIN ANALYZE
SELECT o.order_id, o.order_dt, o.final_cost, s.status_name
FROM order_statuses os
         JOIN orders o ON o.order_id = os.order_id
         JOIN statuses s ON s.status_id = os.status_id
WHERE o.user_id = 'c2885b45-dddd-4df3-b9b3-2cc012df727c'::uuid
  AND os.status_dt IN (SELECT max(status_dt)
                       FROM order_statuses
                       WHERE order_id = o.order_id);

/*
 Hash Join  (cost=301.98..331.47 rows=44 width=54) (actual time=0.052..0.054 rows=2 loops=1)
  Hash Cond: (s.status_id = os.status_id)
  ->  Seq Scan on statuses s  (cost=0.00..22.70 rows=1270 width=36) (actual time=0.004..0.004 rows=6 loops=1)
  ->  Hash  (cost=301.89..301.89 rows=7 width=26) (actual time=0.044..0.044 rows=2 loops=1)
        Buckets: 1024  Batches: 1  Memory Usage: 9kB
        ->  Nested Loop  (cost=4.73..301.89 rows=7 width=26) (actual time=0.028..0.042 rows=2 loops=1)
              ->  Bitmap Heap Scan on orders o  (cost=4.31..15.48 rows=3 width=22) (actual time=0.007..0.008 rows=2 loops=1)
                    Recheck Cond: (user_id = 'c2885b45-dddd-4df3-b9b3-2cc012df727c'::uuid)
                    Heap Blocks: exact=1
                    ->  Bitmap Index Scan on orders_user_id_idx  (cost=0.00..4.31 rows=3 width=0) (actual time=0.005..0.005 rows=2 loops=1)
                          Index Cond: (user_id = 'c2885b45-dddd-4df3-b9b3-2cc012df727c'::uuid)
              ->  Index Scan using idx_order_statuses_order_id_status_id on order_statuses os  (cost=0.42..95.44 rows=3 width=20) (actual time=0.013..0.015 rows=1 loops=2)
                    Index Cond: (order_id = o.order_id)
                    Filter: (SubPlan 1)
                    Rows Removed by Filter: 5
                    SubPlan 1
                      ->  Aggregate  (cost=15.90..15.91 rows=1 width=8) (actual time=0.002..0.002 rows=1 loops=12)
                            ->  Index Scan using idx_order_statuses_order_id_status_id on order_statuses  (cost=0.42..15.89 rows=5 width=8) (actual time=0.001..0.001 rows=6 loops=12)
                                  Index Cond: (order_id = o.order_id)
Planning Time: 0.256 ms
Execution Time: 0.083 ms
*/

-- Время выполнения запроса 0.054. В общем запрос выглядит достаточно эффективным. Наиболее дорогой
-- операцией является hash join. Также присутствует один Seq Scan.

EXPLAIN ANALYZE
SELECT DISTINCT ON (o.order_id) o.order_id, o.order_dt, o.final_cost, s.status_name
FROM orders o
         JOIN order_statuses os ON o.order_id = os.order_id
         JOIN statuses s ON s.status_id = os.status_id
WHERE o.user_id = 'c2885b45-dddd-4df3-b9b3-2cc012df727c'::uuid
ORDER BY o.order_id, os.status_dt DESC;

-- Попробуем добавить индекс order_statuses (order_id, status_dt DESC) это позволит постгре
-- быстро находить статус для каждого order_id без сканирования всей таблицы. А также создадим
-- индекс на orders (user_id, order_id) потому что они используются для фильтрации и объединения.

CREATE INDEX idx_order_statuses_order_id_status_dt ON order_statuses (order_id, status_dt DESC);
CREATE INDEX idx_orders_user_id_order_id ON orders (user_id, order_id);

-- Обновим статистику
VACUUM ANALYZE orders;
VACUUM ANALYZE order_statuses;
VACUUM ANALYZE statuses;

-- Попробуем переписать запрос с использованием DISTINCT ON, одновременно отсортируем по
-- os.status_id DESC и тогда получим последний статус для каждого заказа.
EXPLAIN ANALYZE
SELECT DISTINCT ON (o.order_id) o.order_id, o.order_dt, o.final_cost, s.status_name
FROM orders o
         JOIN order_statuses os ON o.order_id = os.order_id
         JOIN statuses s ON s.status_id = os.status_id
WHERE o.user_id = 'c2885b45-dddd-4df3-b9b3-2cc012df727c'::uuid
ORDER BY o.order_id, os.status_dt DESC;

-- Тоже самое только через оконную функцию.
EXPLAIN ANALYZE
WITH latest_statuses AS (SELECT os.order_id,
                                os.status_id,
                                os.status_dt,
                                ROW_NUMBER() OVER (PARTITION BY os.order_id ORDER BY os.status_dt DESC) AS rn
                         FROM order_statuses os)
SELECT o.order_id, o.order_dt, o.final_cost, s.status_name
FROM orders o
         JOIN latest_statuses ls ON o.order_id = ls.order_id AND ls.rn = 1
         JOIN statuses s ON ls.status_id = s.status_id
WHERE o.user_id = 'c2885b45-dddd-4df3-b9b3-2cc012df727c'::uuid;

-- Значимо увеличить скорость не удалось, возможно не хватает данных что-бы различия в скоростях
-- проявлялись. Прирост скорости при использовании варианта с оконной функцией и DISTINCT ON
-- составил примерно 50%. План запроса для оконной функции приведён ниже.
/*
Nested Loop  (cost=0.70..9434.36 rows=1 width=46) (actual time=0.028..0.040 rows=2 loops=1)
  Join Filter: (ls.status_id = s.status_id)
  Rows Removed by Join Filter: 10
  ->  Merge Join  (cost=0.70..9433.23 rows=1 width=26) (actual time=0.023..0.032 rows=2 loops=1)
        Merge Cond: (ls.order_id = o.order_id)
        ->  Subquery Scan on ls  (cost=0.42..9415.32 rows=622 width=12) (actual time=0.015..0.021 rows=3 loops=1)
              Filter: (ls.rn = 1)
              ->  WindowAgg  (cost=0.42..7861.14 rows=124334 width=28) (actual time=0.014..0.020 rows=3 loops=1)
                    Run Condition: (row_number() OVER (?) <= 1)
                    ->  Index Scan using idx_order_statuses_order_id_status_dt on order_statuses os  (cost=0.42..5685.30 rows=124334 width=20) (actual time=0.010..0.012 rows=13 loops=1)
        ->  Index Scan using idx_orders_user_id_order_id on orders o  (cost=0.29..16.34 rows=3 width=22) (actual time=0.006..0.007 rows=2 loops=1)
              Index Cond: (user_id = 'c2885b45-dddd-4df3-b9b3-2cc012df727c'::uuid)
  ->  Seq Scan on statuses s  (cost=0.00..1.06 rows=6 width=28) (actual time=0.002..0.002 rows=6 loops=2)
Planning Time: 0.239 ms
Execution Time: 0.065 ms */

-- Запрос 15
-- вычисляет количество заказов позиций, продажи которых выше среднего
EXPLAIN ANALYZE
SELECT d.name, SUM(count) AS orders_quantity
FROM order_items oi
         JOIN dishes d ON d.object_id = oi.item
WHERE oi.item IN (SELECT item
                  FROM (SELECT item, SUM(count) AS total_sales
                        FROM order_items oi
                        GROUP BY 1) dishes_sales
                  WHERE dishes_sales.total_sales > (SELECT SUM(t.total_sales) / COUNT(*)
                                                    FROM (SELECT item, SUM(count) AS total_sales
                                                          FROM order_items oi
                                                          GROUP BY 1) t))
GROUP BY 1
ORDER BY orders_quantity DESC;

/*
 Sort  (cost=4808.91..4810.74 rows=735 width=66) (actual time=27.141..27.151 rows=362 loops=1)
  Sort Key: (sum(oi.count)) DESC
  Sort Method: quicksort  Memory: 48kB
  InitPlan 1 (returns $0)
    ->  Aggregate  (cost=1501.65..1501.66 rows=1 width=32) (actual time=7.886..7.886 rows=1 loops=1)
          ->  HashAggregate  (cost=1480.72..1490.23 rows=761 width=40) (actual time=7.803..7.857 rows=761 loops=1)
                Group Key: oi_2.item
                Batches: 1  Memory Usage: 169kB
                ->  Seq Scan on order_items oi_2  (cost=0.00..1134.48 rows=69248 width=16) (actual time=0.002..2.119 rows=69248 loops=1)
  ->  HashAggregate  (cost=3263.06..3272.25 rows=735 width=66) (actual time=27.054..27.086 rows=362 loops=1)
        Group Key: d.name
        Batches: 1  Memory Usage: 105kB
        ->  Hash Join  (cost=1522.66..3147.65 rows=23083 width=42) (actual time=16.141..23.535 rows=35854 loops=1)
              Hash Cond: (oi.item = d.object_id)
              ->  Seq Scan on order_items oi  (cost=0.00..1134.48 rows=69248 width=16) (actual time=0.005..2.308 rows=69248 loops=1)
              ->  Hash  (cost=1519.48..1519.48 rows=254 width=50) (actual time=16.132..16.134 rows=366 loops=1)
                    Buckets: 1024  Batches: 1  Memory Usage: 39kB
                    ->  Hash Join  (cost=1497.85..1519.48 rows=254 width=50) (actual time=16.028..16.107 rows=366 loops=1)
                          Hash Cond: (d.object_id = dishes_sales.item)
                          ->  Seq Scan on dishes d  (cost=0.00..19.62 rows=762 width=42) (actual time=0.003..0.035 rows=762 loops=1)
                          ->  Hash  (cost=1494.67..1494.67 rows=254 width=8) (actual time=16.021..16.022 rows=366 loops=1)
                                Buckets: 1024  Batches: 1  Memory Usage: 23kB
                                ->  Subquery Scan on dishes_sales  (cost=1480.72..1494.67 rows=254 width=8) (actual time=15.901..16.001 rows=366 loops=1)
                                      ->  HashAggregate  (cost=1480.72..1492.13 rows=254 width=40) (actual time=15.900..15.988 rows=366 loops=1)
                                            Group Key: oi_1.item
                                            Filter: (sum(oi_1.count) > $0)
                                            Batches: 1  Memory Usage: 169kB
                                            Rows Removed by Filter: 395
                                            ->  Seq Scan on order_items oi_1  (cost=0.00..1134.48 rows=69248 width=16) (actual time=0.001..2.238 rows=69248 loops=1)
Planning Time: 0.139 ms
Execution Time: 27.197 ms
 */

-- Время выполнения запроса составляет 27.151. Наиболее дорогой операцией является финальная
-- сортировка. Оптимизировать запрос можно добавив индексы и применив CTE.

-- Начнём с индексов
CREATE INDEX idx_order_items_item ON order_items (item);
CREATE INDEX idx_dishes_object_id ON dishes (object_id);

-- Перепишем запрос под CTE.
EXPLAIN ANALYZE
WITH dish_sales AS (SELECT item, SUM(count) AS total_sales
                    FROM order_items
                    GROUP BY item),
     average_sales AS (SELECT SUM(total_sales) / COUNT(*) AS avg_sales
                       FROM dish_sales)
SELECT d.name, SUM(oi.count) AS orders_quantity
FROM order_items oi
         JOIN dishes d ON d.object_id = oi.item
         JOIN dish_sales ds ON ds.item = oi.item
         JOIN average_sales a ON ds.total_sales > a.avg_sales
GROUP BY d.name
ORDER BY orders_quantity DESC;

/* Sort  (cost=3108.01..3109.85 rows=735 width=66) (actual time=19.347..19.356 rows=362 loops=1)
  Sort Key: (sum(oi.count)) DESC
  Sort Method: quicksort  Memory: 48kB
  CTE dish_sales
    ->  HashAggregate  (cost=1480.72..1490.23 rows=761 width=40) (actual time=8.103..8.162 rows=761 loops=1)
          Group Key: order_items.item
          Batches: 1  Memory Usage: 169kB
          ->  Seq Scan on order_items  (cost=0.00..1134.48 rows=69248 width=16) (actual time=0.003..2.248 rows=69248 loops=1)
  ->  HashAggregate  (cost=1573.60..1582.79 rows=735 width=66) (actual time=19.251..19.284 rows=362 loops=1)
        Group Key: d.name
        Batches: 1  Memory Usage: 105kB
        ->  Nested Loop  (cost=48.47..1458.34 rows=23052 width=42) (actual time=8.373..16.366 rows=35854 loops=1)
              ->  Hash Join  (cost=48.17..76.41 rows=254 width=50) (actual time=8.363..8.508 rows=366 loops=1)
                    Hash Cond: (ds.item = d.object_id)
                    ->  Nested Loop  (cost=19.03..43.78 rows=254 width=8) (actual time=8.271..8.363 rows=366 loops=1)
                          Join Filter: (ds.total_sales > ((sum(dish_sales.total_sales) / (count(*))::numeric)))
                          Rows Removed by Join Filter: 395
                          ->  Aggregate  (cost=19.03..19.04 rows=1 width=32) (actual time=8.269..8.269 rows=1 loops=1)
                                ->  CTE Scan on dish_sales  (cost=0.00..15.22 rows=761 width=32) (actual time=8.105..8.225 rows=761 loops=1)
                          ->  CTE Scan on dish_sales ds  (cost=0.00..15.22 rows=761 width=40) (actual time=0.000..0.032 rows=761 loops=1)
                    ->  Hash  (cost=19.62..19.62 rows=762 width=42) (actual time=0.086..0.087 rows=762 loops=1)
                          Buckets: 1024  Batches: 1  Memory Usage: 66kB
                          ->  Seq Scan on dishes d  (cost=0.00..19.62 rows=762 width=42) (actual time=0.005..0.041 rows=762 loops=1)
              ->  Index Scan using idx_order_items_item on order_items oi  (cost=0.29..4.53 rows=91 width=16) (actual time=0.001..0.017 rows=98 loops=366)
                    Index Cond: (item = d.object_id)
Planning Time: 0.224 ms
Execution Time: 19.415 ms
*/

-- Скорость исполнения запроса улучшилась и составила 19.356 против 27.151. Таким образом цель
-- улучшить скорость на 30% достигнута.
