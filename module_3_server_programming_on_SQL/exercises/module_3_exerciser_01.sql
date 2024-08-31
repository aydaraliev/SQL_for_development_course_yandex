/* 1. Собаки размещаются в вольерах в зависимости от их размера: маленькие, средние или
    большие.
Напишите функцию get_current_dogs_count, которая выводит количество собак, проживающих в
гостинице на настоящий день, на основании таблицы staff_schedule. Функция должна возвращать
значение типа integer. */

INSERT INTO student.staff_schedule(day, staff_id, dogs_count)
VALUES (CURRENT_DATE, 1, 5);
/*
не удаляйте код выше этого комментария, он нужен для корректной работы тренажёра
*/
CREATE OR REPLACE FUNCTION get_current_dogs_count()
    RETURNS integer
    LANGUAGE SQL
AS
$$
SELECT SUM(dogs_count)
FROM staff_schedule
WHERE day = CURRENT_DATE;
$$;

/* 2. Напишите функцию get_total_price, которая предварительно подсчитывает цену бронирования
по таким параметрам:
    id вольера,
    количество дней.
За долгосрочное пребывание в гостинице предусмотрены скидки:
    5% на всё бронирование — при проживании 5 дней и более.
    10% — 10 дней и более.
    20% — 20 дней и более.

Функция должна возвращать значение типа numeric, округлённое до двух цифр после запятой.
Например, если вольер стоимостью 1 000.00 руб. в сутки бронируется на 11 дней, цена
рассчитывается так: 1 000.00 руб. х 11 дней х коэффициент 0.9 = 9 900.00 */

CREATE OR REPLACE FUNCTION get_total_price(enclosure_id int, number_of_days int)
    RETURNS numeric
    LANGUAGE SQL
AS
$$
SELECT CASE
           WHEN number_of_days < 10 AND number_of_days >= 5 THEN ROUND(price * number_of_days * 0.95, 2)
           WHEN number_of_days < 20 AND number_of_days >= 10 THEN ROUND(price * number_of_days * 0.9, 2)
           WHEN number_of_days >= 20 THEN ROUND(price * number_of_days * 0.8, 2)
           ELSE ROUND(price * number_of_days, 2)
           END as stay_price
FROM ENCLOSURES
WHERE id = enclosure_id;
$$;

/* 3. Стоимость вольеров хранится в таблице enclosures в столбце price. Напишите процедуру
change_enclosure_price, которая умножает цену вольера на заданный коэффициент.
Процедура принимает такие параметры:
    id вольера,
    коэффициент с типом numeric, на который умножается price.
При умножении цены на коэффициент результат должен округляться до двух знаков после запятой.*/

CREATE OR REPLACE PROCEDURE change_enclosure_price(enclosure_id integer, coefficient numeric)
    LANGUAGE SQL
AS
$$
UPDATE enclosures
SET price = ROUND(price * coefficient, 2)
WHERE id = enclosure_id
$$;