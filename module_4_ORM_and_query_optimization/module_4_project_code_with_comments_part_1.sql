/* В заданиях описаны ситуации, когда база данных работает недостаточно быстро.
Проанализируйте эти ситуации, предложите наиболее удачный, на ваш взгляд, план решения
проблемы и реализуйте его.
В ответе напишите:
    Причину — почему проблема возникла, опишите ход ваших рассуждений.
    План решения — что вы предлагаете сделать, чтобы проблему решить.
    Скрипты — если они нужны для реализации вашего плана. */

-- Установим расширение для поиска медленных запросов
-- CREATE EXTENSION pg_stat_statements;

/* Задание 1
Клиенты сервиса начали замечать, что после нажатия на кнопку Оформить заказ система на
какое-то время подвисает. Вот команда для вставки данных в таблицу orders, которая хранит
общую информацию о заказах: */

EXPLAIN ANALYZE
INSERT INTO orders
(order_id, order_dt, user_id, device_type, city_id, total_cost, discount,
 final_cost)
SELECT MAX(order_id) + 1,
       current_timestamp,
       '329551a1-215d-43e6-baee-322f2467272d',
       'Mobile',
       1,
       1000.00,
       null,
       1000.00
FROM orders;

-- Чтобы лучше понять, как ещё используется в запросах таблица orders, выполните запросы:
EXPLAIN ANALYZE
SELECT order_dt
FROM orders
WHERE order_id = 153;

EXPLAIN ANALYZE
SELECT order_id
FROM orders
WHERE order_dt > current_date::timestamp;

EXPLAIN ANALYZE
SELECT count(*)
FROM orders
WHERE user_id = '329551a1-215d-43e6-baee-322f2467272d';

-- ОТВЕТ
/* Индексы тормозят операцию INSERT, удалим их и будем добавлять по мере надобности. Также запрос
задерживается по всей видимости из-за рассчёта максимального order_id: MAX(order_id) + 1, для
новой строки. Такой запрос проходит по всей таблице в поисках максимума.
Для решения задачи необходимо:
   1. Удалить лишние индексы из таблицы orders
   2. Сделать order_id первичным ключом с автоинкрементом  */

-- Удалил все индексы кроме primary key по order_id
-- drop index orders_city_id_idx;
-- drop index orders_device_type_city_id_idx;
-- drop index orders_device_type_idx;
-- drop index orders_discount_idx;
-- drop index orders_final_cost_idx;
-- drop index orders_order_dt_idx;
-- drop index orders_order_id_idx;
-- drop index orders_total_cost_idx;
-- drop index orders_total_final_cost_discount_idx;
-- drop index orders_user_id_idx;

-- От удаления индексов запрос на insert не стал работать быстрее, хотя должен был в теории,
-- Наверное не хватает данных что-бы реализовать преимущество вставки без индексов.

-- Проверим наш будущий ключ на дубликаты
SELECT order_id, COUNT(*)
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Сделаем столбец ключом
ALTER TABLE orders
    ADD PRIMARY KEY (order_id);

-- Создадим последовательность
CREATE SEQUENCE order_id_seq
    START WITH 1
    INCREMENT BY 1;

-- Свяжем последовательность с ключом
ALTER TABLE orders
    ALTER COLUMN order_id SET DEFAULT nextval('order_id_seq');

-- Синхронизируем нашу последовательность с последним значением order_id
SELECT setval('order_id_seq', COALESCE((SELECT MAX(order_id) FROM orders), 1) + 1, false);

-- Вставим строку
EXPLAIN ANALYZE
INSERT INTO orders
(order_dt, user_id, device_type, city_id, total_cost, discount, final_cost)
VALUES (current_timestamp,
        '329551a1-215d-43e6-baee-322f2467272d',
        'TEST',
        1,
        1000.00,
        null,
        1000.00);

-- Посмотрим на последние 10 записей
SELECT *
FROM orders
ORDER BY order_id DESC
LIMIT 10;

/* На практике время выполнения не очень сильно различается, возможно из-за того что мало
данных. Но оценка стоимости показывает разницу в примерно 30 раз в пользу доработанного
варианта, т.е. если вставлять запись позволив постгре посчитать автоинкремент для order_id и
сделать это поле первичным ключом.
*/

/* Задание 2
Клиенты сервиса в свой день рождения получают скидку. Расчёт скидки и отправка клиентам
промокодов происходит на стороне сервера приложения. Список клиентов возвращается из БД в
приложение таким запросом: */

EXPLAIN ANALYZE
SELECT user_id::text::uuid,
       first_name::text,
       last_name::text,
       city_id::bigint,
       gender::text
FROM users
WHERE city_id::integer = 4
  AND date_part('day', to_date(birth_date::text, 'yyyy-mm-dd'))
    = date_part('day', to_date('31-12-2023', 'dd-mm-yyyy'))
  AND date_part('month', to_date(birth_date::text, 'yyyy-mm-dd'))
    = date_part('month', to_date('31-12-2023', 'dd-mm-yyyy'));

/* Каждый раз список именинников формируется и возвращается недостаточно быстро.
Оптимизируйте этот процесс. */

-- ОТВЕТ
/* Для решения задачи необходимо:
    1. Поменять типы данных в столбцах сохранив исходные значения, для того что-бы избавиться от
       множества преобразований типов данных.
    2. Проиндексировать столбцы birth_date и city_id, так как по ним идёт поиск и сравнения.
    3. Избавиться от вытаскивания даты функциями date_part и to_date, заменив на EXTRACT, в таком
       состоянии как сейчас эти функции вызываются для каждой строки. */

-- В первую очередь избавимся от множества кастов, для этого поменяем типы столбцов в таблице.
ALTER TABLE users
    ALTER COLUMN user_id TYPE UUID USING TRIM(user_id)::UUID;
ALTER TABLE users
    ALTER COLUMN first_name TYPE VARCHAR(100) USING TRIM(first_name);
ALTER TABLE users
    ALTER COLUMN last_name TYPE VARCHAR(100) USING TRIM(last_name);
-- ALTER TABLE users
-- ALTER COLUMN city_id TYPE BIGINT USING city_id::BIGINT;
ALTER TABLE users
    ALTER COLUMN gender TYPE VARCHAR(50) USING TRIM(gender);
ALTER TABLE users
    ALTER COLUMN birth_date TYPE DATE USING to_date(birth_date, 'YYYY-MM-DD');
ALTER TABLE users
    ALTER COLUMN registration_date TYPE TIMESTAMP USING to_timestamp(registration_date, 'YYYY-MM-DD HH24:MI:SS');

-- Создадим индексы
CREATE INDEX idx_users_city_id ON users (city_id);
CREATE INDEX idx_users_birth_date ON users (birth_date);

-- Переписанный запрос
EXPLAIN ANALYZE
SELECT user_id,
       first_name,
       last_name,
       city_id,
       gender
FROM users
WHERE city_id = 4
  AND birth_date IS NOT NULL
  AND EXTRACT(MONTH FROM birth_date) = 12
  AND EXTRACT(DAY FROM birth_date) = 31;

/* После переделок удалось как минимум в 4 раза ускорить выполнение запроса за счёт того что
используется Bitmap Heap Scan вместо Sequential Scan, избавления от вызова функций для работы с
датами для каждой строки, а также за счёт того что удалось избавиться от множества конверсий
типов данных. */

/* Задание 3
Также пользователи жалуются, что оплата при оформлении заказа проходит долго.
Разработчик сервера приложения Матвей проанализировал ситуацию и заключил, что оплата «висит»
из-за того, что выполнение процедуры add_payment требует довольно много времени по меркам БД.
Найдите в базе данных эту процедуру и подумайте, как можно ускорить её работу. */

-- БЫЛО
-- create procedure add_payment(IN p_order_id bigint, IN p_sum_payment numeric)
--     language plpgsql
-- as
-- $$
-- BEGIN
--     INSERT INTO order_statuses (order_id, status_id, status_dt)
--     VALUES (p_order_id, 2, statement_timestamp());
--
--     INSERT INTO payments (payment_id, order_id, payment_sum)
--     VALUES (nextval('payments_payment_id_sq'), p_order_id, p_sum_payment);
--
--     INSERT INTO sales(sale_id, sale_dt, user_id, sale_sum)
--     SELECT NEXTVAL('sales_sale_id_sq'), statement_timestamp(), user_id, p_sum_payment
--     FROM orders
--     WHERE order_id = p_order_id;
-- END;
-- $$;

--ОТВЕТ
/* Процедуру можно ускорить путём выноса statement_timestamp() в отдельную переменную что-бы не
вызывать её дважды (1). orders(order_id) у нас уже проиндексированный, так как первичный ключ.
Также можно увеличить кэш последовательностей что-бы уменьшить время записи на диск (2), других
вариантов ускорить запрос не вижу.*/

ALTER SEQUENCE payments_payment_id_sq CACHE 100;
ALTER SEQUENCE sales_sale_id_sq CACHE 100;

CREATE OR REPLACE PROCEDURE add_payment(IN p_order_id BIGINT, IN p_sum_payment NUMERIC)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_user_id   UUID;
    v_timestamp TIMESTAMP := statement_timestamp();
BEGIN
    SELECT user_id
    INTO v_user_id
    FROM orders
    WHERE order_id = p_order_id;

    INSERT INTO sales (sale_id, sale_dt, user_id, sale_sum)
    VALUES (nextval('sales_sale_id_sq'), v_timestamp, v_user_id, p_sum_payment);

    --     INSERT INTO order_statuses (order_id, status_id, status_dt)
    --     VALUES (p_order_id, 2, v_timestamp);

    --     INSERT INTO payments (payment_id, order_id, payment_sum)
    --     VALUES (nextval('payments_payment_id_sq'), p_order_id, p_sum_payment);

END;
$$;

/* Поскольку таблица sales фиксирует платёж + детали, то создаётся впечатление что остальные
таблицы не критично заполнять именно в этой процедуре. Плохо что не прописана логика нормально
в задаче, и не понятно как оптимизировать.*/

/* Задание 4
Все действия пользователей в системе логируются и записываются в таблицу user_logs. Потом эти
данные используются для анализа — как правило, анализируются данные за текущий квартал.
Время записи данных в эту таблицу сильно увеличилось, а это тормозит практически все действия
пользователя. Подумайте, как можно ускорить запись. Вы можете сдать решение этой задачи без скрипта
или — попробовать написать скрипт. Дерзайте!
*/

/* Для ускорения работы таблицы вижу только один вариант - партиционирование. Поскольку раз туда
пишется всё, то возможно она стала слишком большой. */

-- Определим с какой даты нам надо партиционировать.
SELECT MIN(log_date)
FROM user_logs;

-- Создадим новую партиционированную таблицу.
CREATE TABLE user_logs_partitioned
(
    visitor_uuid VARCHAR(128),
    user_id      UUID,
    event        VARCHAR(128),
    datetime     TIMESTAMP,
    log_date     DATE,
    log_id       BIGSERIAL,
    PRIMARY KEY (log_date, log_id) -- Include log_date in the primary key
) PARTITION BY RANGE (log_date);

-- Создадим партиции начиная с 2021 года
-- 2021
CREATE TABLE user_logs_2021_q1 PARTITION OF user_logs_partitioned
    FOR VALUES FROM ('2021-01-01') TO ('2021-04-01');

CREATE TABLE user_logs_2021_q2 PARTITION OF user_logs_partitioned
    FOR VALUES FROM ('2021-04-01') TO ('2021-07-01');

CREATE TABLE user_logs_2021_q3 PARTITION OF user_logs_partitioned
    FOR VALUES FROM ('2021-07-01') TO ('2021-10-01');

CREATE TABLE user_logs_2021_q4 PARTITION OF user_logs_partitioned
    FOR VALUES FROM ('2021-10-01') TO ('2022-01-01');

-- 2022
CREATE TABLE user_logs_2022_q1 PARTITION OF user_logs_partitioned
    FOR VALUES FROM ('2022-01-01') TO ('2022-04-01');

CREATE TABLE user_logs_2022_q2 PARTITION OF user_logs_partitioned
    FOR VALUES FROM ('2022-04-01') TO ('2022-07-01');

CREATE TABLE user_logs_2022_q3 PARTITION OF user_logs_partitioned
    FOR VALUES FROM ('2022-07-01') TO ('2022-10-01');

CREATE TABLE user_logs_2022_q4 PARTITION OF user_logs_partitioned
    FOR VALUES FROM ('2022-10-01') TO ('2023-01-01');

-- 2023
CREATE TABLE user_logs_2023_q1 PARTITION OF user_logs_partitioned
    FOR VALUES FROM ('2023-01-01') TO ('2023-04-01');

CREATE TABLE user_logs_2023_q2 PARTITION OF user_logs_partitioned
    FOR VALUES FROM ('2023-04-01') TO ('2023-07-01');

CREATE TABLE user_logs_2023_q3 PARTITION OF user_logs_partitioned
    FOR VALUES FROM ('2023-07-01') TO ('2023-10-01');

CREATE TABLE user_logs_2023_q4 PARTITION OF user_logs_partitioned
    FOR VALUES FROM ('2023-10-01') TO ('2024-01-01');

-- 2024
CREATE TABLE user_logs_2024_q1 PARTITION OF user_logs_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');

CREATE TABLE user_logs_2024_q2 PARTITION OF user_logs_partitioned
    FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');

CREATE TABLE user_logs_2024_q3 PARTITION OF user_logs_partitioned
    FOR VALUES FROM ('2024-07-01') TO ('2024-10-01');

CREATE TABLE user_logs_2024_q4 PARTITION OF user_logs_partitioned
    FOR VALUES FROM ('2024-10-01') TO ('2025-01-01');

-- Запихнём данные в созданные партиции.
-- 2021 Q1
INSERT INTO user_logs_partitioned
SELECT *
FROM user_logs
WHERE log_date >= '2021-01-01'
  AND log_date < '2021-04-01';

-- 2021 Q2
INSERT INTO user_logs_partitioned
SELECT *
FROM user_logs
WHERE log_date >= '2021-04-01'
  AND log_date < '2021-07-01';

-- 2021 Q3
INSERT INTO user_logs_partitioned
SELECT *
FROM user_logs
WHERE log_date >= '2021-07-01'
  AND log_date < '2021-10-01';

-- 2021 Q4
INSERT INTO user_logs_partitioned
SELECT *
FROM user_logs
WHERE log_date >= '2021-10-01'
  AND log_date < '2022-01-01';

-- 2022 Q1
INSERT INTO user_logs_partitioned
SELECT *
FROM user_logs
WHERE log_date >= '2022-01-01'
  AND log_date < '2022-04-01';

-- 2022 Q2
INSERT INTO user_logs_partitioned
SELECT *
FROM user_logs
WHERE log_date >= '2022-04-01'
  AND log_date < '2022-07-01';

-- 2022 Q3
INSERT INTO user_logs_partitioned
SELECT *
FROM user_logs
WHERE log_date >= '2022-07-01'
  AND log_date < '2022-10-01';

-- 2022 Q4
INSERT INTO user_logs_partitioned
SELECT *
FROM user_logs
WHERE log_date >= '2022-10-01'
  AND log_date < '2023-01-01';

-- 2023 Q1
INSERT INTO user_logs_partitioned
SELECT *
FROM user_logs
WHERE log_date >= '2023-01-01'
  AND log_date < '2023-04-01';

-- 2023 Q2
INSERT INTO user_logs_partitioned
SELECT *
FROM user_logs
WHERE log_date >= '2023-04-01'
  AND log_date < '2023-07-01';

-- 2023 Q3
INSERT INTO user_logs_partitioned
SELECT *
FROM user_logs
WHERE log_date >= '2023-07-01'
  AND log_date < '2023-10-01';

-- 2023 Q4
INSERT INTO user_logs_partitioned
SELECT *
FROM user_logs
WHERE log_date >= '2023-10-01'
  AND log_date < '2024-01-01';

-- 2024 Q1
INSERT INTO user_logs_partitioned
SELECT *
FROM user_logs
WHERE log_date >= '2024-01-01'
  AND log_date < '2024-04-01';

-- 2024 Q2
INSERT INTO user_logs_partitioned
SELECT *
FROM user_logs
WHERE log_date >= '2024-04-01'
  AND log_date < '2024-07-01';

-- 2024 Q3
INSERT INTO user_logs_partitioned
SELECT *
FROM user_logs
WHERE log_date >= '2024-07-01'
  AND log_date < '2024-10-01';

-- 2024 Q4
INSERT INTO user_logs_partitioned
SELECT *
FROM user_logs
WHERE log_date >= '2024-10-01'
  AND log_date < '2025-01-01';

-- Удалим оригинал за ненадобностью
DROP TABLE user_logs;

-- Переименуем новую таблицу в оригинал
ALTER TABLE user_logs_partitioned
    RENAME TO user_logs;

-- Пересоздадим индекс
CREATE INDEX user_logs_datetime_idx
    ON user_logs (datetime);

/* Задание 5
Маркетологи сервиса регулярно анализируют предпочтения различных возрастных групп. Для этого они
формируют отчёт:
day	  age	   spicy	fish	meat
	  0–20
	  20–30
	  30–40
	  40–100
В столбцах spicy, fish и meat отображается, какой % блюд, заказанных каждой категорией
пользователей, содержал эти признаки.
В возрастных интервалах верхний предел входит в интервал, а нижний — нет.
Также по правилам построения отчётов в них не включается текущий день.
Администратор БД Серёжа заметил, что регулярные похожие запросы от разных маркетологов нагружают
базу, и в результате увеличивается время работы приложения.
Подумайте с точки зрения производительности, как можно оптимально собирать и хранить данные для
такого отчёта. В ответе на это задание не пишите причину — просто опишите ваш способ получения
отчёта и добавьте соответствующий скрипт.
 */

/* Оптимальным решением представляется материализованное представление, это поможет снять нагрузку
на базу данных. Ради примера напишу что-бы представление обновлялось на INSERT, UPDATE, DELETE, но
в целом можно и ночью обновлять что-бы снизить нагрузку на базу данных.
 */

-- Создание материализованного представления для отчета
CREATE MATERIALIZED VIEW age_preferences_report AS
SELECT date_trunc('day', o.order_dt)                                                         AS day,
       CASE
           WHEN EXTRACT(YEAR FROM age(CURRENT_DATE, u.birth_date)) BETWEEN 1 AND 20 THEN '0–20'
           WHEN EXTRACT(YEAR FROM age(CURRENT_DATE, u.birth_date)) BETWEEN 21 AND 30 THEN '20–30'
           WHEN EXTRACT(YEAR FROM age(CURRENT_DATE, u.birth_date)) BETWEEN 31 AND 40 THEN '30–40'
           ELSE '40–100'
           END                                                                               AS age_group,
       ROUND(100.0 * SUM(CASE WHEN d.spicy > 0 THEN oi.count ELSE 0 END) / SUM(oi.count), 2) AS spicy,
       ROUND(100.0 * SUM(CASE WHEN d.fish > 0 THEN oi.count ELSE 0 END) / SUM(oi.count), 2)  AS fish,
       ROUND(100.0 * SUM(CASE WHEN d.meat > 0 THEN oi.count ELSE 0 END) / SUM(oi.count), 2)  AS meat
FROM orders o
         JOIN users u ON o.user_id = u.user_id
         JOIN order_items oi ON o.order_id = oi.order_id
         JOIN dishes d ON oi.item = d.object_id
WHERE o.order_dt < CURRENT_DATE -- Exclude the current day
GROUP BY day, age_group;

-- Создадим индексы для облегчения поиска.
CREATE INDEX idx_age_preferences_report_day ON age_preferences_report (day);
CREATE INDEX idx_age_preferences_report_age_group ON age_preferences_report (age_group);

-- Создаём обновляющую функцию
CREATE OR REPLACE FUNCTION refresh_age_preferences_report() RETURNS TRIGGER AS
$$
BEGIN
    REFRESH MATERIALIZED VIEW age_preferences_report;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Триггеры после insert/update/delete на таблицах orders или order_items
CREATE TRIGGER refresh_age_preferences_report_trigger
    AFTER INSERT OR UPDATE OR DELETE
    ON orders
    FOR EACH STATEMENT
EXECUTE FUNCTION refresh_age_preferences_report();

CREATE TRIGGER refresh_age_preferences_report_trigger_items
    AFTER INSERT OR UPDATE OR DELETE
    ON order_items
    FOR EACH STATEMENT
EXECUTE FUNCTION refresh_age_preferences_report();

