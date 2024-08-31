/* 1. Ваша компания готовит материал для туристического издания. Новый номер будет посвящён
Москве, а статья от вашего проекта — экскурсии по кремлям города. Нужно найти все кремли на
территории столицы.
Напишите запрос, которые выведет все имена объектов из таблицы kremlins в пределах Москвы
(поле name равно «Москва»). */

SELECT kremlins.name
FROM kremlins
         JOIN cities ON ST_Within(
        ST_GeomFromWKB(kremlins.shape),
        ST_GeomFromWKB(cities.shape))
WHERE cities.name = 'Москва';

/* 2. Сейчас таблица cities содержит информацию не обо всех городах. Нужно составить
список городов, данные о которых нужно добавить в БД. Для этого найдите кремли, для
которых не удаётся установить город с помощью таблицы cities.
Напишите запрос, которые вернёт имена всех объектов, которые не входят ни в один из
геометрических объектов таблицы cities. */

SELECT kremlins.name
FROM kremlins
         LEFT JOIN cities ON ST_Within(
        ST_GeomFromWKB(kremlins.shape),
        ST_GeomFromWKB(cities.shape))
WHERE cities.name is NULL;

/* 3. Пиар-отдел планирует создать видеосюжет о самых крупных кремлях.
Подготовьте данные для материала:
    Выведите таблицу из двух столбцов: название кремля и его площадь в квадратных метрах.
    Площадь округлите до целого числа.
    Дайте псевдоним столбцу с площадью: area.
    Отсортируйте выборку по убыванию площади. */

SELECT k.name,
       ROUND(ST_Area(k.shape::geography)) as area
FROM kremlins k
ORDER BY area DESC;

/* 4. У продакт-менеджера новая идея — он предлагает выделить объекты, которые занимают
большую относительную площадь. Помогите ему подготовить данные:
    Для кремлей, которые попадают в один из городов таблицы cities, посчитайте отношение
      площади кремля к площади города.
    Результат выведите в процентах (умножьте результат деления на 100).
    Выведите два столбца: имя кремля и столбец ratio с посчитанным показателем.
    Результат отсортируйте по убыванию значения ratio. */

SELECT k.name,
       (ST_Area(k.shape::geography) / ST_Area(c.shape::geography)) * 100 AS ratio
FROM kremlins k
         JOIN cities c ON ST_Within(ST_GeomFromWKB(k.shape), ST_GeomFromWKB(c.shape))
ORDER BY ratio DESC;

/* 5. Найдите два кремля, которые находятся максимально далеко друг от друга. Выведите три
столбца: kremlin_1, kremlin_2, distance, где в первых двух столбцах — названия найденных
кремлей, а третий — расстояние в метрах между ними, округлённое до целого числа. */

WITH k_cross AS (SELECT k1.name             AS kremlin_1,
                        k2.name             AS kremlin_2,
                        k1.shape::geography as k1_place,
                        k2.shape::geography as k2_place
                 FROM kremlins k1,
                      kremlins k2
                 WHERE k1.name != k2.name)
SELECT kremlin_1,
       kremlin_2,
       ROUND(ST_Distance(k1_place, k2_place)) AS distance
FROM k_cross
ORDER BY ROUND(ST_Distance(k1_place, k2_place)) DESC
LIMIT 1;
