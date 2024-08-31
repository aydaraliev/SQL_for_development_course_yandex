/* 1. Перепишите один из своих прошлых запросов с использованием ключевого слова WITH.
Сначала получите 40 самых длинных фильмов, аренда которых составляет больше двух долларов.
Затем проанализируйте данные о возрастных рейтингах отобранных фильмов. Выгрузите в итоговую
таблицу такие поля:
    rating — возрастной рейтинг;
    length — минимальное, максимальное и среднее значения длительности, назовите поля
      min_length, max_length и avg_length соответственно;
    rental_rate — минимум, максимум и среднее для цены просмотра, назовите поля
      min_rental_rate, max_rental_rate, avg_rental_rate соответственно.
Отсортируйте финальную таблицу по средней длительности фильма по возрастанию. */

WITH filtered_movies AS (SELECT rating, length, rental_rate
                         FROM movie
                         WHERE rental_rate > 2.00
                         ORDER BY length DESC
                         LIMIT 40)
SELECT rating,
       MIN(length)      AS min_length,
       MAX(length)      AS max_length,
       AVG(length)      AS avg_length,
       MIN(rental_rate) AS min_rental_rate,
       MAX(rental_rate) AS max_rental_rate,
       AVG(rental_rate) AS avg_rental_rate
FROM filtered_movies
GROUP BY rating
ORDER BY avg_length;

/* 2.
Проанализируйте данные из таблицы invoice за 2012 и 2013 годы. В итоговую таблицу должны
войти поля:
    month — номер месяца;
    sum_total_2012 — выручка за этот месяц в 2012 году;
    sum_total_2013 — выручка за этот месяц в 2013 году;
    perc — процент, который отображает, насколько изменилась месячная выручка в 2013
    году по сравнению с 2012 годом.
Округлите значение в поле perc до ближайшего целого числа. Отсортируйте таблицу по значению
в поле month от меньшего к большему. */

WITH monthly_revenue AS (SELECT EXTRACT(YEAR FROM invoice_date::date)  AS year,
                                EXTRACT(MONTH FROM invoice_date::date) AS month,
                                SUM(total)                             AS sum_total
                         FROM invoice
                         WHERE EXTRACT(YEAR FROM invoice_date::date) IN (2012, 2013)
                         GROUP BY EXTRACT(YEAR FROM invoice_date::date), EXTRACT(MONTH FROM invoice_date::date))
SELECT m2012.month,
       COALESCE(m2012.sum_total, 0) AS sum_total_2012,
       COALESCE(m2013.sum_total, 0) AS sum_total_2013,
       ROUND(
               CASE
                   WHEN m2012.sum_total IS NOT NULL AND m2013.sum_total IS NOT NULL THEN
                       ((m2013.sum_total - m2012.sum_total) / m2012.sum_total) * 100
                   WHEN m2012.sum_total IS NULL THEN
                       100
                   WHEN m2013.sum_total IS NULL THEN
                       -100
                   ELSE
                       0
                   END
       )                            AS perc
FROM (SELECT month, sum_total FROM monthly_revenue WHERE year = 2012) m2012
         FULL OUTER JOIN
         (SELECT month, sum_total FROM monthly_revenue WHERE year = 2013) m2013
         ON m2012.month = m2013.month
ORDER BY m2012.month;
