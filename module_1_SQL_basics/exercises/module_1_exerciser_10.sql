/* 1. Выведите названия всех треков, добавив информацию о датах, в которые эти треки
покупали. Важно, чтобы в выборку вошли все треки — даже если их никто не купил.
Чтобы получить нужный результат, надо соединить три таблицы, ведь таблица invoice,
которая хранит данные о дате заказа, не содержит информации о купленных треках.
Сначала соедините таблицы track и invoice_line по ключу track_id, а затем присоедините
таблицу invoice по ключу invoice_id. В итоговую таблицу поместите два поля: name из
таблицы track и invoice_date из таблицы invoice. Приведите дату к нужному формату.
*/

SELECT t.name,
       i.invoice_date::date
FROM track t
         LEFT JOIN invoice_line il
                   USING (track_id)
         LEFT JOIN invoice i
                   ON il.invoice_id = i.invoice_id;

/* 2. Отобразите названия фильмов, в которых снимались актёры и актрисы,
не указанные в базе. */

SELECT f.title
FROM movie f -- assuming the actual table name is movie, as indicated in the prompt
         LEFT JOIN film_actor fa ON f.film_id = fa.film_id
WHERE fa.actor_id IS NULL;

/* 3. Отобразите на экране имена исполнителей, для которых в базе данных не нашлось
ни одного музыкального альбома. */

SELECT a.name
FROM artist a
         LEFT JOIN album al
                   USING (artist_id)
WHERE album_id IS NULL;