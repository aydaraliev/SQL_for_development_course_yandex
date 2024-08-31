/* 1. Перед открытием интернет-магазин Chinook наполняли данными с помощью импортёра-обработчика.
Импорт данных произошёл с неточностями. Так, в базе данных есть категория фильмов “Children”,
но при импорте данных некоторые фильмы из этой категории получили рейтинг 'NC-17' (лица 17-летнего
возраста и младше на фильм не допускаются).
В детском режиме дети и подростки не могут посмотреть часть контента. Ошибка влияет на выручку и
вызывает негативные отзывы клиентов.
Необходимо исправить ошибку и дать возможность детям смотреть детские фильмы — установить рейтинг 'R'
(лица, не достигшие 17-летнего возраста, допускаются на фильм только в сопровождении одного из родителей
либо законного представителя). Составьте команду UPDATE для смены рейтинга фильмов. */

UPDATE movie m
SET rating = 'R'
FROM film_category fc
         JOIN category c ON fc.category_id = c.category_id
WHERE m.film_id = fc.film_id
  AND c.name = 'Children'
  AND m.rating = 'NC-17';

/*  2. В этом году юбилей у актёра Джонни Кейджа (англ. Johnny Cage). В юбилейной рекламной кампании участвует
и интернет-магазин Chinook. В рамках кампании нужно дополнить описание фильмов, в которых принимал участие актёр,
фразой 'Actor Johnny Cage takes part in the film.'.
Составьте команду UPDATE, которая дополнит поле description в таблице movie фразой 'Actor Johnny Cage takes part
in the film.', для фильмов, где принимал участие этот актёр.
Для решения задания вам пригодится строковая операция конкатенации ||: text || text → text. Выражение description
|| '. Actor Johnny Cage takes part in the film.' добавляет фразу справа, в результате получается нужная строка.
В прекоде это уже есть. */

UPDATE movie m
SET description = description || '. Actor Johnny Cage takes part in the film.'
FROM film_actor fa
         JOIN actor a ON fa.actor_id = a.actor_id
WHERE m.film_id = fa.film_id
  AND a.first_name = 'Johnny'
  AND a.last_name = 'Cage'
RETURNING m.film_id, m.title, m.description, a.first_name, a.last_name;

/* 3. Стало известно, что трек Balls to the Wall был продан «в чудовищном качестве» — именно так описывают его
разгневанные клиенты. Заменить проданный трек на трек с надлежащим качеством оказалось невозможно. Покупателям
вернули деньги, осталось актуализировать базу данных. Начальник IT-службы дал указание удалить в таблице invoice_line
записи о продажах, которые относятся к треку Balls to the Wall.
Составьте команду DELETE для удаления этих записей из таблицы invoice_line. */

DELETE
FROM invoice_line il
    USING track, invoice
WHERE il.track_id = track.track_id
  AND il.invoice_id = invoice.invoice_id
  AND track.name = 'Balls to the Wall'
RETURNING il.invoice_id, il.track_id, track.name;