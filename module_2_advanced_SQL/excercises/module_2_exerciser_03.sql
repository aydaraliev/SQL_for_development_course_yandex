/* 1. Составьте сводную таблицу. Посчитайте заказы, оформленные за каждый месяц в течение
нескольких лет: с 2011 по 2013 год включительно. Итоговая таблица должна включать четыре
поля: invoice_month, year_2011, year_2012, year_2013. Поле invoice_month должно хранить
месяц в виде числа от 1 до 12.
Если данные за какой-то месяц отсутствуют, номер такого месяца всё равно должен попасть в
таблицу. В этом задании не будет подсказок. Используйте любые методы, которые посчитаете
нужными. */

SELECT DISTINCT EXTRACT(MONTH FROM i.invoice_date::date) as invoice_month,
                y2011.year_2011,
                y2012.year_2012,
                y2013.year_2013
FROM invoice i
         LEFT JOIN (SELECT EXTRACT(MONTH FROM invoice_date::date) as invoice_month,
                           COUNT(invoice_id)                      as year_2011
                    FROM invoice
                    WHERE invoice_date::date BETWEEN '2011-01-01'::date AND '2011-12-31'::date
                    GROUP BY invoice_month) y2011 ON y2011.invoice_month = EXTRACT(MONTH FROM i.invoice_date::date)
         LEFT JOIN (SELECT EXTRACT(MONTH FROM invoice_date::date) as invoice_month,
                           COUNT(invoice_id)                      as year_2012
                    FROM invoice
                    WHERE invoice_date::date BETWEEN '2012-01-01'::date AND '2012-12-31'::date
                    GROUP BY invoice_month) y2012 ON y2012.invoice_month = EXTRACT(MONTH FROM i.invoice_date::date)
         LEFT JOIN (SELECT EXTRACT(MONTH FROM invoice_date::date) as invoice_month,
                           COUNT(invoice_id)                      as year_2013
                    FROM invoice
                    WHERE invoice_date::date BETWEEN '2013-01-01'::date AND '2013-12-31'::date
                    GROUP BY invoice_month) y2013 ON y2013.invoice_month = EXTRACT(MONTH FROM i.invoice_date::date)
ORDER BY invoice_month;

/* 2. Отберите уникальные фамилии пользователей, которые:
  оформили хотя бы один заказ в январе 2013 года,
  а также сделали хотя бы один заказ в любом другом месяце того же года.
Данные по заказам можно найти в таблице invoice. Пользователей, которые оформили заказы
только в январе, а в остальное время ничего не заказывали, в таблицу включать не нужно. */

SELECT DISTINCT last_name
FROM client
WHERE customer_id IN (SELECT DISTINCT customer_id
                      FROM invoice
                      WHERE customer_id IN (SELECT customer_id
                                            FROM invoice
                                            WHERE invoice_date::date BETWEEN '2013-01-01' and '2013-01-31')
                        AND customer_id IN (SELECT customer_id
                                            FROM invoice
                                            WHERE invoice_date::date BETWEEN '2013-02-01' and '2013-12-31'));

/* 3. Сформируйте статистику по категориям фильмов. Отобразите в итоговой таблице два поля:
  название категории,
  число уникальных фильмов из этой категории.
Фильмы для второго поля нужно отобрать по условию. Посчитайте фильмы только с теми актёрами
и актрисами, которые больше семи раз снимались в фильмах, вышедших после 2013 года.
Назовите поля name_category и total_films соответственно. Отсортируйте таблицу по количеству
фильмов от большего к меньшему, а затем по полю с названием категории в лексикографическом
порядке — по возрастанию. */

SELECT c.name                    AS name_category,
       COUNT(DISTINCT m.film_id) AS total_films
FROM movie m
         JOIN
     film_actor fa USING (film_id)
         JOIN
     film_category fc USING (film_id)
         JOIN
     category c USING (category_id)
WHERE fa.actor_id IN (SELECT fa.actor_id
                      FROM movie m
                               JOIN
                           film_actor fa USING (film_id)
                      WHERE m.release_year > 2013
                      GROUP BY fa.actor_id
                      HAVING COUNT(*) > 7)
GROUP BY c.name
ORDER BY total_films DESC,
         name_category ASC;