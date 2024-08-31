CREATE OR REPLACE PROCEDURE set_daily_bonus(p_date date)
    LANGUAGE plpgsql
AS
$$
DECLARE
    -- объявляем переменную цикла типа record
    _r record;
BEGIN
    -- начинаем цикл для итерации по результатам запроса
    FOR _r IN
        SELECT user_id, SUM(total_distance)::integer daily_distance
        FROM workouts
        WHERE date_time_begin::date = p_date
        GROUP BY user_id
        LOOP
        -- вызываем процедуру для начисления бонуса пользователю
        -- за пройденную им дистанцию
            CALL set_user_bonus(_r.user_id, _r.daily_distance);
        END LOOP;
END;
$$;

CALL set_daily_bonus('2023-09-20'::date);

SELECT *
FROM users_bonus
ORDER BY user_id;

CREATE OR REPLACE FUNCTION get_limited_count(p_arr integer[], p_limit integer)
    RETURNS integer
    LANGUAGE plpgsql
AS
$$
DECLARE
    _el      integer; -- переменная для элементов массива, который будет перебираться
    _sum     integer := 0; -- переменная для хранения суммы элементов, изначально 0
    _counter integer := 0; -- счётчик элементов, изначально 0
BEGIN
    FOREACH _el IN ARRAY p_arr
        LOOP
            _sum = _sum + _el;
            -- как только сумма превышает заданный предел - цикл прерывается
            EXIT WHEN _sum >= p_limit;
            _counter = _counter + 1;
        END LOOP;
    RETURN _counter;
END;
$$;

SELECT get_limited_count('{1, 3, -5, 0, 7, 8, -2}'::integer[], 10);

CREATE OR REPLACE FUNCTION get_sum_positive(p_arr integer[])
    RETURNS integer
    LANGUAGE plpgsql
AS
$$
DECLARE
    _el  integer;
    _sum integer := 0;

BEGIN
    FOREACH _el IN ARRAY p_arr -- инициализируем цикл по элементам массива
        LOOP
            CONTINUE WHEN _el < 0; -- пропускаем отрицательные элементы массива
            _sum = _sum + _el; -- прибавляем к сумме очередной элемент
        END LOOP;
    RETURN _sum;
END;
$$;

SELECT get_sum_positive('{1, 3, -5, 0, 7, 8, -2}'::integer[]);
