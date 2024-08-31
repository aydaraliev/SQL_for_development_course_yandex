/* 1. С помощью функции GENERATE_SERIES сгенерируйте последовательность дат (stat_date) в интервале c 1 по 31
августа 2023 года с интервалом в три дня. */

SELECT CAST(GENERATE_SERIES('2023-08-01'::date, '2023-08-31', '3 days'::interval) AS DATE) AS stat_date

/* 2. Для тестирования базы данных необходимо сгенерировать 50 строк по определённому шаблону:
        * user_id — идентификатор пользователя, шесть заглавных букв английского алфавита;
        * reg_dt — случайная дата в интервале от 20 до 30 августа 2023 года включительно. */

SELECT setseed(0); /* Не удаляйте эту строчку, она позволяет зафиксировать генерацию рандомных значений */
SELECT
    STRING_AGG(CHR(ASCII('A') + FLOOR(RANDOM()*26)::integer), '') AS user_id,
    '2023-08-20'::date + ROUND(RANDOM()*10)::integer AS reg_dt
FROM
     GENERATE_SERIES(1, 6, 1) AS char_num,
     GENERATE_SERIES(1, 50, 1) AS line_num
GROUP BY line_num

/* 3. Используя данные таблицы invoice, подсчитайте сумму заказа (total_sum) за каждый день (check_date)
в ноябре 2013 года. Если в какой-то из дней не было заказов, замените NULL на 0. Результат отсортируйте по
дате в порядке возрастания. Данные check_date приведите к дате. */

SELECT gs.check_date::date,
       CASE WHEN sum(i.total) IS NULL THEN 0 ELSE sum(total) END AS total_sum
FROM
GENERATE_SERIES('2013-11-01'::timestamp, '2013-11-30', '1 day'::interval) as gs(check_date)
LEFT JOIN invoice i ON gs.check_date::date = i.invoice_date::date
GROUP BY gs.check_date
ORDER BY gs.check_date;