/* 1. Отберите названия уникальных категорий фильмов, в которых снималась Эмили Ди
   (англ. Emily Dee). */

SELECT DISTINCT name
FROM category c
         JOIN film_category fc
              ON c.category_id = fc.category_id
         JOIN film_actor fa
              ON fc.film_id = fa.film_id
         JOIN actor a
              ON fa.actor_id = a.actor_id
WHERE a.first_name = 'Emily'
  AND a.last_name = 'Dee';

/* 2. На очереди — сотрудники (таблица staff). У некоторых сотрудников есть
менеджеры — их идентификаторы указаны в поле reports_to. Посмотрите внимательно
на схему базы: таблица staff отсылает сама к себе. Это нормально, можно не
создавать новую таблицу с менеджерами.
Разберёмся в иерархии команды. Отобразите таблицу с двумя полями: в первое поле
внесите фамилии всех сотрудников, а во второе — фамилии их менеджеров. Назовите
поля employee_last_name и manager_last_name. */

SELECT e.last_name as employee_last_name,
       m.last_name as manager_last_name
FROM staff e
         LEFT JOIN staff m ON e.reports_to = m.employee_id;

