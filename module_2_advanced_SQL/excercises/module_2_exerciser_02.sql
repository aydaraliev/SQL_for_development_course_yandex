/* 1. Вам нужно написать запрос для сравнения выручки в разных странах по заказам с
определёнными условиями по такому алгоритму:
  Написать подзапрос, который выгрузит заказы, где больше пяти треков.
  Написать подзапрос, который найдёт среднее значение цены одного трека.
  Объединить эти подзапросы в основной запрос, в котором станет известно минимальное,
   максимальное и среднее значение выручки для каждой страны.
Напишите код для первого подзапроса. Таблица invoice_line хранит информацию о купленных
треках. Выгрузите из неё только те заказы (поле invoice_id), которые включают больше
пяти треков.
*/

SELECT invoice_id
FROM invoice_line
GROUP BY invoice_id
HAVING count(invoice_id) > 5;

/* 2. Теперь напишите код для второго подзапроса. С помощью той же таблицы (invoice_line)
найдите среднее значение цены одного трека (поле unit_price). */

SELECT avg(unit_price) avg_price
FROM invoice_line;

/* 3. Объедините написанные запросы из предыдущих заданий в подзапросе и напишите основной
запрос. Используйте в подзапросах код, написанный в предыдущих заданиях, он уже дан в прекоде.
Для каждой страны (поле billing_country) посчитайте минимальное, максимальное и среднее
   значение выручки из поля total. Назовите поля так: min_total, max_total и avg_total,
   каждое из полей округлите до двух знаков после запятой. Нужные поля для выгрузки
   хранит таблица invoice.
При подсчёте учитывайте только те заказы, которые включают более пяти треков. Стоимость
   заказа должна превышать среднюю цену одного трека.
Отсортируйте итоговую таблицу по двум полям: сначала по значению в поле avg_total от
   большего к меньшему, затем по названию страны billing_country в алфавитном порядке. */

SELECT billing_country,
       round(min(total), 2) min_total,
       round(max(total), 2) max_total,
       round(avg(total), 2) avg_total
FROM invoice
WHERE invoice_id in (SELECT invoice_id
                     FROM invoice_line
                     GROUP BY invoice_id
                     HAVING COUNT(invoice_id) > 5)
  AND invoice_id > (SELECT AVG(unit_price)
                    FROM invoice_line)
GROUP BY billing_country
ORDER BY avg_total DESC, billing_country;

/* 4. Отберите два самых коротких по продолжительности трека и выгрузите названия их жанров. */
SELECT name
FROM genre
WHERE genre_id in
      (SELECT genre_id
       FROM track
       ORDER BY milliseconds
       LIMIT 2);

/* 5. Выгрузите уникальные названия городов, в которых стоимость заказов превышает
   максимальное значение за 2009 год. */

SELECT DISTINCT billing_city
FROM invoice
WHERE total > (SELECT max(total)
               FROM invoice
               WHERE invoice_date::date
                         BETWEEN CAST('2009-01-01' AS DATE)
                         AND CAST('2009-12-31' AS DATE));

/* 6. Посчитайте по категориям фильмов среднее значение продолжительности этих фильмов.
Сделайте это только для тех фильмов, которые попадают в возрастной рейтинг с самыми
дорогими для аренды фильмами.
Найдите возрастной рейтинг с самыми дорогими для аренды фильмами: посчитайте среднюю
   стоимость аренды фильмов (столбец rental_rate) каждого рейтинга из таблицы movie.
Отсортируйте значения в обратном порядке и возьмите название рейтинга из первой строки.
Выведите названия категорий фильмов с этим рейтингом.
Добавьте второе поле со средним значением продолжительности фильмов. */

SELECT cat.name        AS category_name,
       AVG(mov.length) AS average_length
FROM movie mov
         JOIN
     film_category fc ON mov.film_id = fc.film_id
         JOIN
     category cat ON fc.category_id = cat.category_id
WHERE mov.rating = (
    -- Subquery to find the rating with the highest average rental rate
    SELECT rating
    FROM movie
    GROUP BY rating
    ORDER BY AVG(rental_rate) DESC
    LIMIT 1)
GROUP BY cat.name
ORDER BY cat.name;
