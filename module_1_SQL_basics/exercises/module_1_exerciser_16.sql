/* 1. Подсчитайте количество альбомов из таблицы album, в названии которых больше 10 символов. */

SELECT count(album_id)
FROM album
WHERE LENGTH(title) > 10;

/* 2. Потренируйтесь создавать новую строку при объединении нескольких строк. Для каждого сотрудника из таблицы
staff выгрузите почтовый адрес для отправки корреспонденции. Назовите поле post_address. Почтовый адрес отформатируйте
так: Имя Фамилия, адрес, город, штат индекс, СТРАНА.
Обратите внимание на разделители: одни значения разделяются запятой, другие — простым пробелом. Чтобы адрес выглядел
корректно, имя и фамилию пропишите с заглавной буквы, а название страны в верхнем регистре. Чтобы соединить строки,
примените функцию CONCAT. */

SELECT CONCAT(INITCAP(first_name), ' ',
              INITCAP(last_name), ', ',
              address, ', ',
              city, ', ',
              state, ' ',
              postal_code, ', ',
              UPPER(country)) as post_address
FROM staff;

/* 3. Выведите уникальные значения доменов из поля email таблицы client в новом поле domain_name.
Значения выведите в формате name.domain — например, yahoo.de. Используйте функции STRPOS и SUBSTR. */

SELECT DISTINCT SUBSTR(email, STRPOS(email, '@') + 1)
FROM client;

/* 4. Перечислите через запятую с пробелом названия всех фильмов (поле title) из таблицы movie для каждой
категории фильмов (поле name) из таблицы category. Выберите все фильмы, которые относятся к каждой категории,
и выведите их в новом поле movies. Отсортируйте фильмы в алфавитном порядке. Чтобы связать название фильма и
категорию, используйте таблицу film_category. */

SELECT c.name,
       STRING_AGG(m.title, ', ' ORDER BY m.title) as movies
FROM movie m
         JOIN film_category fc
              USING (film_id)
         JOIN category c
              USING (category_id)
GROUP BY c.name;