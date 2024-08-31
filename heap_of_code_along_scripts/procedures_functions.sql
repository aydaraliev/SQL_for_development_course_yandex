-- Создаём процедуру с тремя входными параметрами
CREATE OR REPLACE PROCEDURE add_workout_data(p_workout_id integer, p_heart_rate integer, p_distance numeric)
    LANGUAGE SQL
AS
$$
    -- Вставляем данные в таблицу physiological_indicators
INSERT INTO physiological_indicators(workout_id, date_time, heart_rate)
VALUES (p_workout_id, CURRENT_TIMESTAMP, p_heart_rate);

    -- Вставляем данные в таблицу distances
INSERT INTO distances(workout_id, date_time, distance)
VALUES (p_workout_id, CURRENT_TIMESTAMP, p_distance);
$$;

CALL add_workout_data(1001, 130, 350.1);

SELECT *
FROM physiological_indicators
WHERE workout_id = 1001
ORDER BY date_time DESC
LIMIT 1;

SELECT *
FROM distances
WHERE workout_id = 1001
ORDER BY date_time DESC
LIMIT 1;

DROP PROCEDURE add_workout_data(p_workout_id integer, p_heart_rate integer, p_distance numeric);

CREATE OR REPLACE FUNCTION add_workout_data(p_workout_id integer, p_heart_rate integer, p_distance numeric)
    RETURNS void
    LANGUAGE plpgsql
AS
$$
BEGIN
    INSERT INTO physiological_indicators(workout_id, date_time, heart_rate)
    VALUES (p_workout_id, current_timestamp, p_heart_rate);

    INSERT INTO distances(workout_id, date_time, distance)
    VALUES (p_workout_id, current_timestamp, p_distance);
END;
$$;

CREATE OR REPLACE PROCEDURE test()
    LANGUAGE plpgsql
AS
$$
BEGIN
    SELECT add_workout_data(1001, 130, 350.1);
END;
$$;

CALL test();

CREATE OR REPLACE PROCEDURE test()
    LANGUAGE plpgsql
AS
$$
BEGIN
    PERFORM add_workout_data(1, 130, 100.1);
END;
$$;

CALL test();