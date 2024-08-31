/* 1. Посчитайте минимальный, максимальный и средний год выпуска фильмов (release_year) из
таблицы movie. Средний год округлите до целого числа. */

SELECT min(release_year), max(release_year), round(avg(release_year))
FROM movie;

/* 2. Посчитайте, сколько пропусков содержит поле fax из таблицы client. */

SELECT count(*) - count(fax)
FROM client;

/* 3. В таблице media_type есть пять типов треков. Из них четыре относятся к аудио — содержат в поле
   media_type.name слово audio, — а один относится к видео: Protected MPEG-4 video file.
   Посчитайте, сколько стоит приобрести все видеотреки. Цена треков указана в столбце unit_price таблицы track. */

SELECT sum(t.unit_price)
FROM track t
         JOIN media_type mt ON t.media_type_id = mt.media_type_id
WHERE mt.name NOT LIKE '%audio%';

/* 4. Среди категорий фильмов есть три категории на букву C — Children, Classics, Comedy.
   Посчитайте общее количество фильмов в этих трёх категориях. */

SELECT count(fc.film_id)
FROM film_category fc
         JOIN category c
              USING (category_id)
WHERE c.name LIKE 'C%';

/* 5. Посчитайте количество альбомов, в которых встречаются треки в жанре Jazz. */

SELECT count(DISTINCT a.album_id)
FROM album a
         JOIN track t
              USING (album_id)
         JOIN genre g ON t.genre_id = g.genre_id
WHERE g.name = 'Jazz';

/* 6. Проверьте, какую выручку в среднем приносит каждый покупатель. Выгрузите общую сумму выручки,
число уникальных покупателей (поле customer_id) и среднюю выручку на уникального пользователя для страны США */

SELECT sum(i.total), count(DISTINCT i.customer_id), sum(i.total) / count(DISTINCT i.customer_id)
FROM invoice i
WHERE billing_country = 'USA';