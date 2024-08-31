CREATE OR REPLACE PROCEDURE end_workout(p_workout_id bigint)
    LANGUAGE plpgsql
AS
$$
DECLARE
    _total_distance numeric; -- Общая дистанция за тренировку
BEGIN
    -- Получаем общую дистанцию суммированием всех дистанций из таблицы distances
    SELECT SUM(distance)
    INTO _total_distance
    FROM distances
    WHERE workout_id = p_workout_id;
END;
$$;

CREATE OR REPLACE PROCEDURE end_workout(p_workout_id bigint)
    LANGUAGE plpgsql
AS
$$
DECLARE
    _total_distance numeric;
    _date_time_end  timestamp := CURRENT_TIMESTAMP;
BEGIN
    SELECT SUM(distance)
    INTO _total_distance
    FROM distances
    WHERE workout_id = p_workout_id;
END;
$$;

CREATE OR REPLACE FUNCTION average_speed_kmh(p_distance numeric, p_dt_begin timestamp, p_dt_end timestamp)
    RETURNS numeric
    LANGUAGE sql
AS
$$
SELECT p_distance * 0.06 / extract(minutes from (p_dt_end - p_dt_begin));
$$;

--финальная функция

CREATE OR REPLACE PROCEDURE end_workout(p_workout_id bigint)
    LANGUAGE plpgsql
AS
$$
DECLARE
    _total_distance numeric;
    _date_time_end  timestamp := CURRENT_TIMESTAMP;
    _user_id        integer;
BEGIN
    -- Вычисляем общую дистанцию за тренировку
    SELECT SUM(distance)
    INTO _total_distance
    FROM distances
    WHERE workout_id = p_workout_id;

    -- Обновляем дату окончания, средний пульс и скорость
    UPDATE workouts
    SET date_time_end      = _date_time_end,
        average_speed      = average_speed_kmh(_total_distance, date_time_begin, _date_time_end),
        average_heart_rate = (SELECT AVG(heart_rate) FROM physiological_indicators WHERE workout_id = p_workout_id),
        total_distance     = _total_distance
    WHERE id = p_workout_id;

    -- Получаем id пользователя
    SELECT user_id
    INTO _user_id
    FROM workouts
    WHERE id = p_workout_id;

    -- Добавляем дистанцию к группе
    CALL add_distance_to_user_groups(_user_id, _total_distance);
END;
$$;

CREATE OR REPLACE PROCEDURE end_workout(p_workout_id bigint)
    LANGUAGE plpgsql
AS
$$
DECLARE
    _total_distance numeric;
    _date_time_end  timestamp := CURRENT_TIMESTAMP;
    _user_id        integer;
BEGIN
    SELECT SUM(distance)
    INTO _total_distance
    FROM distances
    WHERE workout_id = p_workout_id;

    UPDATE workouts
    SET date_time_end      = _date_time_end,
        average_speed      = average_speed_kmh(_total_distance, date_time_begin, _date_time_end),
        average_heart_rate = (SELECT AVG(heart_rate) FROM physiological_indicators WHERE workout_id = p_workout_id),
        total_distance     = _total_distance
    WHERE id = p_workout_id;

    COMMIT;

    SELECT user_id
    INTO _user_id
    FROM workouts
    WHERE id = p_workout_id;

    CALL add_distance_to_user_groups(_user_id, _total_distance);
END;
$$;

CREATE OR REPLACE FUNCTION average_speed_kmh(p_distance numeric, p_dt_begin timestamp, p_dt_end timestamp)
    RETURNS numeric
    LANGUAGE sql
AS
$$
SELECT p_distance * 0.06 / extract(minutes from (p_dt_end - p_dt_begin));
$$;

SELECT average_speed_kmh(
               0.0,
               CURRENT_TIMESTAMP::TIMESTAMP,
               CURRENT_TIMESTAMP::TIMESTAMP + interval '10 seconds'
       );

CREATE OR REPLACE FUNCTION average_speed_kmh(p_distance numeric, p_dt_begin timestamp, p_dt_end timestamp)
    RETURNS numeric
    LANGUAGE plpgsql
AS
$$
BEGIN
    RETURN p_distance * 0.06 / extract(minutes from (p_dt_end - p_dt_begin));
EXCEPTION
    WHEN division_by_zero THEN
        RAISE NOTICE 'Ошибка выполнения: %', SQLERRM;
        RETURN NULL;
END;
$$;

SELECT average_speed_kmh(
               0.0,
               CURRENT_TIMESTAMP::timestamp,
               CURRENT_TIMESTAMP::timestamp + interval '10 seconds'
       );

CREATE OR REPLACE PROCEDURE end_workout(p_workout_id bigint)
    LANGUAGE plpgsql
AS
$$
DECLARE
    _total_distance numeric;
    _date_time_end  timestamp := CURRENT_TIMESTAMP;
    _user_id        integer;
BEGIN
    BEGIN
        -- Выделяем этот кусок кода в отдельный блок
        SELECT user_id
        INTO STRICT _user_id -- добавляем STRICT
        FROM workouts
        WHERE id = p_workout_id;
    EXCEPTION
        WHEN no_data_found THEN
            RAISE NOTICE 'Не найдена тренировка с id %', p_workout_id;
            RETURN;
    END;

    SELECT SUM(distance)
    INTO _total_distance
    FROM distances
    WHERE workout_id = p_workout_id;

    UPDATE workouts
    SET date_time_end      = _date_time_end,
        average_speed      = average_speed_kmh(_total_distance, date_time_begin,
                                               _date_time_end),
        average_heart_rate =
            (SELECT AVG(heart_rate)
             FROM physiological_indicators
             WHERE workout_id = p_workout_id)
    WHERE id = p_workout_id;

    COMMIT;

    CALL add_distance_to_user_groups(_user_id, _total_distance);
END;
$$;

CALL end_workout(1000); 