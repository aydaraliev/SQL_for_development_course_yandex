/* 1. Управляющий Smily Dog Иннокентий хочет узнать, для собак каких пород вольеры
бронируют на самый длительный срок, а для каких — на самый короткий. Найдите ответ с
помощью анонимного блока. Результат выведите в виде сообщения такого формата:
Для крупных пород средняя продолжительность бронирования, дней: Х
Для средних пород средняя продолжительность бронирования, дней: Y
Для мелких пород средняя продолжительность бронирования, дней: Z */

DO
LANGUAGE plpgsql
$$
    DECLARE
        _avg_big    int;
        _avg_medium int;
        _avg_small  int;
    BEGIN
        SELECT AVG(date_end - date_begin)
        INTO _avg_big
        from bookings as bk
                 join dogs as d on d.id = bk.dog_id
                 join breeds as b ON d.breed_id = b.id
        WHERE b.dog_type_id = 3;

        SELECT AVG(date_end - date_begin)
        INTO _avg_medium
        from bookings as bk
                 join dogs as d on d.id = bk.dog_id
                 join breeds as b ON d.breed_id = b.id
        WHERE b.dog_type_id = 2;

        SELECT AVG(date_end - date_begin)
        INTO _avg_small
        from bookings as bk
                 join dogs as d on d.id = bk.dog_id
                 join breeds as b ON d.breed_id = b.id
        WHERE b.dog_type_id = 1;

        RAISE NOTICE 'Для крупных пород средняя продолжительность бронирования, дней: %',_avg_big;
        RAISE NOTICE 'Для средних пород средняя продолжительность бронирования, дней: %',_avg_medium;
        RAISE NOTICE 'Для мелких пород средняя продолжительность бронирования, дней: %',_avg_small;

    END;
$$;

/* Менеджеры по бронированию заметили, что иногда при переносе брони информация об этом
в системе отображается некорректно. Вы нашли в документации, что за изменение бронирования
отвечает целый ряд функций. Одна из них update_booking, которая принимает следующие
параметры:
    id бронирования, тип integer.
    дата начала бронирования новая, тип date.
    дата окончания бронирования новая, тип date.
Также известно, что эта функция возвращает тип void.
Ваша задача: не имея доступа к коду этой функции, определить, верно ли она работает.
Для этого используйте анонимный блок кода. Внутри него проверьте работу функции
update_booking и выведите сообщение:
update_booking test - t/f
Вместо t/f в сообщении должен стоять результат проверки функции: t, если она сработала верно,
и f — если неверно. */

DO
$$
    DECLARE
        _new_date_begin date;
        _new_date_end   date;
    BEGIN
        INSERT INTO bookings(id, enclosure_id, dog_id, date_begin, date_end, total_price)
        VALUES (-1, 1, 1, current_date, current_date + interval '3 days', 100);

        -- Вызовите проверяемую функцию
        PERFORM update_booking(
                -1,
                (current_date + interval '4 days')::date,
                (current_date + interval '5 days')::date
                );

        SELECT date_begin, date_end
        INTO _new_date_begin, _new_date_end
        FROM bookings
        WHERE id = -1;

        RAISE NOTICE 'update_booking - %'
            , _new_date_begin = current_date + interval '4 days' AND
              _new_date_end = current_date + interval '5 days';
    END;
$$