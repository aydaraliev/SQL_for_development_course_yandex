/* 1. В магазине музыки и фильмов Chinook существует доска почёта. На неё попадают сотрудники
отдела продаж, которые оформили для клиентов покупок на наибольшую сумму. Чтобы следить за
показателями сотрудников, создайте представление top_salesman, которое будет выводить фамилию
(last_name), имя (first_name) и сумму продаж (total_sum) для всех сотрудников из таблицы staff.
Результаты в выводе представления отсортируйте по убыванию столбца total_sum. */

CREATE VIEW top_salesman AS
SELECT s.last_name,
       s.first_name,
       SUM(i.total) AS total_sum
FROM staff s
         JOIN
     client c ON s.employee_id = c.support_rep_id
         JOIN
     invoice i ON c.customer_id = i.customer_id
GROUP BY s.last_name, s.first_name
ORDER BY total_sum DESC;

SELECT *
FROM top_salesman;

/* 2. Создайте представление happy_new_year с единственным столбцом days, которое
вернёт целое число, равное количеству дней до 1 января следующего года. */

CREATE VIEW happy_new_year AS
SELECT '2025-01-01' - CURRENT_DATE as days;
SELECT days
FROM happy_new_year;

/* 3. В базе данных есть представление happy_new_year, которое вы создали раньше.
Поменяйте тип данных, которое возвращает представление, с целого числа на interval.
Подберите нужный способ изменения представления. */

DROP VIEW IF EXISTS happy_new_year;
CREATE VIEW happy_new_year AS
SELECT ('2025-01-01' - CURRENT_DATE) * '1 day'::interval AS days;

SELECT days
FROM happy_new_year;

/* 4. Коллеги попросили переименовать представление happy_new_year и присвоить ему имя
v_days_before_new_year. Сделайте это одним запросом. */

ALTER VIEW happy_new_year RENAME TO v_days_before_new_year;

SELECT days
FROM v_days_before_new_year;