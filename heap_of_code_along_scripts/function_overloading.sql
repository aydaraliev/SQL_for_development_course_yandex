ALTER TABLE users
    ADD COLUMN computer_brand text;

ALTER TABLE users
    ADD COLUMN computer_serial text;

CREATE OR REPLACE FUNCTION find_user(p_email text)
    RETURNS integer
    LANGUAGE SQL
AS
$$
SELECT id
FROM users
WHERE email = p_email
$$;

CREATE OR REPLACE FUNCTION find_user(
    p_computer_brand text,
    p_computer_serial text
)
    RETURNS integer
    LANGUAGE SQL
AS
$$
SELECT id
FROM users
WHERE computer_brand = p_computer_brand
  AND computer_serial = p_computer_serial
$$;

UPDATE users
SET email           = 'ennell@mail.com',
    computer_brand  = 'First Brand',
    computer_serial = 'Sc123456'
WHERE id = 1;

UPDATE users
SET email           = 'unaa@mail.com',
    computer_brand  = 'Best Comp',
    computer_serial = '00J567'
WHERE id = 2;

SELECT find_user('ennell@mail.com');

SELECT find_user('Best Comp', '00J567');

CREATE OR REPLACE FUNCTION check_speed(
    p_speed numeric,
    p_user_id integer,
    p_period text DEFAULT NULL -- Добавляем параметр, в который передаётся период
)
    RETURNS text
    LANGUAGE plpgsql
AS
$$
DECLARE
    _result text;
BEGIN
    SELECT CASE
               WHEN p_speed > MAX(average_speed) THEN 'Новый рекорд!'
               WHEN p_speed < MIN(average_speed) THEN 'Вы можете лучше!'
               ELSE 'Хорошая тренировка!'
               END
    INTO _result
    FROM workouts
    WHERE user_id = p_user_id
      AND (p_period IS NULL OR
           date_time_begin >= CURRENT_DATE - ('1 ' || p_period)::INTERVAL);

    RETURN _result;
EXCEPTION
    WHEN invalid_datetime_format THEN
        RETURN 'Некорректный интервал';
END;
$$;

INSERT INTO workouts (user_id, date_time_begin, date_time_end,
                      average_speed, average_heart_rate, total_distance)
VALUES (7, CURRENT_TIMESTAMP - INTERVAL '1 week',
        CURRENT_TIMESTAMP - INTERVAL '1 week' + INTERVAL '30 minutes',
        25, 110, 10000),
       (7, CURRENT_TIMESTAMP - INTERVAL '2 months',
        CURRENT_TIMESTAMP - INTERVAL '2 months' + INTERVAL '30 minutes',
        20, 120, 10000);

SELECT check_speed(22, 7, 'month');

SELECT check_speed(22::numeric, 7);

DROP PROCEDURE add_distance_to_user_groups(integer, numeric);

CREATE OR REPLACE PROCEDURE add_distance_to_user_groups(
    p_user_id integer,
    p_distance numeric,
    out p_result smallint -- Новый выходной параметр
)
    LANGUAGE plpgsql
AS
$$
BEGIN
    UPDATE group_totals
    SET total_distance = total_distance + p_distance
    WHERE group_id IN (SELECT group_id
                       FROM users_in_groups
                       WHERE user_id = p_user_id);

    p_result := 1; -- Процедура отработала успешно
EXCEPTION
    WHEN others THEN
        p_result := 0; -- В процессе выполнения возникла ошибка
END;
$$;

SELECT get_user_physiological_indicators(8);