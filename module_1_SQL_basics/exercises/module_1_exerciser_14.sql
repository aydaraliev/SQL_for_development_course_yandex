/* 1. Сравните фильмы разных возрастных рейтингов. Найдите среднее значение цены аренды фильма в поле
rental_rate для каждого рейтинга (поле rating). Оставьте в таблице только те записи, в которых среднее значение
rental_rate больше 3. */

SELECT rating, avg(rental_rate)
FROM movie
GROUP BY rating
HAVING avg(rental_rate) > 3;

/* 2. Изучите заказы, которые оформили в сентябре 2011 года. Сравните общую сумму выручки (поле total)
за каждый день этого месяца: выведите день в формате '2011-09-01' и сумму. Информацию о дате заказа хранит
поле invoice_date. Измените тип данных в этом поле, чтобы использовать операторы для работы с датой. Оставьте
в таблице только те значения суммы, которые больше 1 и меньше 10. */

SELECT sum(total) as sum_total,
       CAST(invoice_date AS date)
FROM invoice
WHERE invoice_date >= '2011-09-01'
  AND invoice_date <= '2011-09-30'
GROUP BY invoice_date
HAVING sum(total) > 1
   AND sum(total) < 10;

/* 3. Посчитайте пропуски в поле с почтовым индексом billing_postal_code для каждой страны (поле billing_country).
Получите срез: в таблицу должны войти только те записи, в которых поле billing_address не содержит слов Street,
Way, Road или Drive. Отобразите в таблице страну и число пропусков, если их больше 10. */

SELECT billing_country,
       COUNT(*) - COUNT(billing_postal_code) as missing_po
FROM invoice
WHERE billing_address !~ 'Street|Way|Road|Drive'
GROUP BY billing_country
HAVING (COUNT(*) - COUNT(billing_postal_code)) > 10

/* 4.
Выведите все альбомы, сумма стоимости треков в которых меньше 5 долларов (цены в столбце unit_price таблицы
track указаны в долларах). Отсортируйте альбомы от самых дорогих к самым дешёвым. Результат должен содержать
два столбца — название альбома (столбец title таблицы album) и сумму стоимости треков из этого альбома.
Столбцу c суммой дайте псевдоним album_price. */

SELECT a.title,
       SUM(t.unit_price) AS album_price
FROM album a
JOIN track t ON a.album_id = t.album_id
GROUP BY a.title
HAVING SUM(t.unit_price) < 5
ORDER BY album_price DESC;

/* 5. Группировку можно использовать для поиска и вывода дубликатов по определённым столбцам. Найдите в таблице client
повторяющиеся имена клиентов, для этого выведите два столбца — имя клиента (first_name) и количество строк с таким
именем. */

SELECT c.first_name, COUNT(c.first_name) AS count_name
FROM client c
GROUP BY c.first_name
HAVING COUNT(c.first_name) > 1;
