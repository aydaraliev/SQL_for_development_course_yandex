/* 1. Найдите 40 самых длинных фильмов среди тех, аренда которых составляет больше
двух долларов. Выведите на экран:
  название фильма — title,
  цену аренды — rental_rate,
  длительность фильма — length,
  возрастной рейтинг — rating. */

SELECT title, rental_rate, length, rating
FROM movie
WHERE rental_rate > 2
ORDER BY length DESC
LIMIT 40;

/* 2. Проанализируйте данные о возрастных рейтингах отобранных фильмов. Выгрузите в
итоговую таблицу такие поля:
  возрастной рейтинг — rating;
  минимальное и максимальное значения длительности фильма — min_length и max_length
   соответственно;
  среднее значение длительности фильма — avg_length;
  минимум, максимум и среднее для цены просмотра — min_rental_rate, max_rental_rate,
   avg_rental_rate соответственно.
Отсортируйте запрос по средней длительности фильма по возрастанию. */

SELECT rating,
       min(length)      as min_length,
       max(length)      as max_length,
       avg(length)      as avg_length,
       min(rental_rate) as min_rental_rate,
       max(rental_rate) as max_rental_rate,
       avg(rental_rate) as avg_rental_rate
FROM (SELECT title,
             rental_rate,
             length,
             rating
      FROM movie
      WHERE rental_rate > 2
      ORDER BY length DESC
      LIMIT 40) as top_40
GROUP BY rating
ORDER BY avg_length;

/* 3. Найдите средние значения полей, в которых указаны минимальная и
максимальная длительность отобранных фильмов. Отобразите только эти два поля.
Назовите их avg_min_length и avg_max_length соответственно. */

SELECT avg(min_length) as avg_min_length,
       avg(max_length) as avg_max_length
FROM (SELECT top.rating,
             MIN(top.length)      AS min_length,
             MAX(top.length)      AS max_length,
             AVG(top.length)      AS avg_length,
             MIN(top.rental_rate) AS min_rental_rate,
             MAX(top.rental_rate) AS max_rental_rate,
             AVG(top.rental_rate) AS avg_rental_rate
      FROM (SELECT title,
                   rental_rate,
                   length,
                   rating
            FROM movie
            WHERE rental_rate > 2
            ORDER BY length DESC
            LIMIT 40) AS top
      GROUP BY top.rating
      ORDER BY avg_length) as movies_grouped;

/* 4. Отберите альбомы, названия которых содержат слово 'Rock' и производные от него.
В этих альбомах должно быть восемь или более треков. Выведите на экран одно число — среднее
количество композиций в отобранных альбомах. */

SELECT avg(track_number)
FROM (SELECT a.title, count(t.name) as track_number
      FROM album a
               JOIN track t ON a.album_id = t.album_id
      WHERE a.title LIKE '%Rock%'
      GROUP BY a.title
      HAVING count(t.name) >= 8) as track_count;
