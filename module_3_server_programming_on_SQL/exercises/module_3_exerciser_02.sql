/* 1. Напишите функцию enclosure_available, которая по id вольера определяет, можно ли его
забронировать в определённую дату или же там уже есть шерстяной постоялец. Функция принимает
два параметра в таком порядке:
    id вольера.
    интересующая дата.
Функция возвращает тип boolean. */

CREATE OR REPLACE FUNCTION enclosure_available(enclosure_id INT, check_date DATE)
    RETURNS BOOLEAN
    LANGUAGE plpgsql
AS
$$
DECLARE
    count_bookings INT;
BEGIN
    SELECT COUNT(*)
    INTO count_bookings
    FROM bookings
    WHERE enclosure_id = enclosure_id
      AND check_date BETWEEN date_begin AND date_end;

    IF count_bookings = 0 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$;

/* 2. Напишите запрос SELECT, который выберет id вольера, свободного для бронирования. В запрос
передаётся id собаки, а также дата начала и дата конца проживания в формате date. Запрос
находит вольер, в котором может проживать собака определённого вида и который свободен на
эти даты. Если доступных вольеров несколько, запрос возвращает только один результат.
С помощью этого запроса найдите вольер, доступный для проживания собаки с id = 3 c 01.11.2023
по 05.11.2023.
В предложении WHERE вам нужно проверить, что одновременно выполняются два условия:
    id собаки = 3,
    все дни между датой начала и конца бронирования доступны.
Для проверки второго условия используйте функцию generate_series — она разложит дату начала
и конца периода бронирования на множество дней. Присвойте этому множеству алиас days — и
тогда вы сможете работать с ним как с таблицей. Каждое значение из этой таблицы обозначается
как days.*, и вы сможете передать его в функцию enclosure_available. Если число получившихся
в результате этого строк равно разнице между датой начала и конца нового
бронирования — вольер свободен. */

SELECT enclosures.id
FROM enclosures
WHERE enclosures.dog_type_id = (SELECT b.dog_type_id
                                FROM dogs d
                                         JOIN breeds b ON d.id = b.id
                                WHERE d.id = 3)
  AND (SELECT count(*) = extract(epoch from age('2023-11-05'::date, '2023-11-01'::date)) / 86400 + 1
       FROM generate_series('2023-11-01'::date, '2023-11-04'::date, '1 day'::interval) days
       WHERE enclosure_available(enclosures.id, days.*::date))
LIMIT 1;

/* 3. Создайте процедуру add_booking, которая добавляет строку в таблицу bookings.
Используйте входные параметры в таком порядке:
    id собаки,
    дата начала бронирования,
    дата окончания бронирования.
При написании процедуры используйте переменные.
Если не получается подобрать вольер для собаки с переданным видом, выведите сообщение
NOTICE: «На желаемый период нет свободных вольеров». Для поиска свободных вольеров
используйте запрос из предыдущего задания. */

CREATE OR REPLACE PROCEDURE add_booking(in integer, in date, in date)
    LANGUAGE plpgsql
AS
$$
DECLARE
    _id_v    integer;
    _days    integer;
    _price_v numeric;
BEGIN
    BEGIN
        SELECT e.id
        INTO STRICT _id_v
        FROM enclosures e
                 JOIN breeds b ON e.dog_type_id = b.dog_type_id
                 JOIN dogs d ON b.id = d.breed_id
        WHERE d.id = $1
          AND (SELECT count(*) > 0
               FROM generate_series($2, $3, interval '1 day') days
               WHERE enclosure_available(e.id, days.*::date))
        LIMIT 1;
    EXCEPTION
        WHEN no_data_found THEN
            RAISE NOTICE 'На желаемый период нет свободных вольеров';
            RETURN;
    END;

    _days := ($3 - $2);

    INSERT INTO bookings(enclosure_id, dog_id, date_begin, date_end, total_price)
    VALUES (_id_v, $1, $2, $3, student.get_total_price(_id_v, _days));

END;
$$;
