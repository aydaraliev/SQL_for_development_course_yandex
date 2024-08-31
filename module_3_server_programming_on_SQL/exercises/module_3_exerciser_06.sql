/* 1. В одном из заданий предыдущей темы вы написали процедуру add_dog_to_schedule(in date),
которая обновляет таблицу staff_schedule, увеличивая количество собак на содержании в
заданный день.
Вспомните код процедуры:
CREATE OR REPLACE PROCEDURE add_dog_to_schedule(in date)
LANGUAGE sql
AS $$
    UPDATE staff_schedule
    SET dogs_count = dogs_count + 1
    WHERE day = $1;
$$;
Когда питомец находится в гостинице, каждый день его пребывания вызывается эта процедура.
Например, если питомец приезжает на три дня, процедура будет выполнена трижды. Для
автоматизации процесса напишите процедуру, которая с помощью цикла вызовет нужное количество
раз процедуру add_dog_to_schedule(in date). Назовите новую процедуру
add_dog_to_schedule(p_from date, p_to date), где:
    p_from_date — дата поступления питомца в гостиницу,
    p_to_date — дата окончания пребывания. */

CREATE OR REPLACE PROCEDURE add_dog_to_schedule(in date)
    LANGUAGE sql
AS
$$
UPDATE staff_schedule
SET dogs_count = dogs_count + 1
WHERE day = $1;
$$;

CREATE OR REPLACE PROCEDURE add_dog_to_schedule(p_from_date date, p_to_date date)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_current_date date; -- Using a different variable name to avoid conflict
BEGIN
    -- Initialize the loop with the start date
    v_current_date := p_from_date;

    -- Loop through each date in the range
    WHILE v_current_date <= p_to_date
        LOOP
            -- Call the existing procedure for the current date
            CALL add_dog_to_schedule(v_current_date);

            -- Move to the next day
            v_current_date := v_current_date + INTERVAL '1 day';
        END LOOP;
END;
$$;

/* 2.
Для выполнения рабочих задач отделу статистики компании «Вело-вжик» нужна функция, которая
вычисляет количество выходных дней между двумя указанными датами. Выходными днями считают
субботу и воскресенье.
Напишите функцию get_weekends_count(p_from_date date, p_to_date date), которая:
    принимает два параметра типа дата;
    возвращает целое число — количество выходных в интервале дат, включая даты начала и конца.

Для итерации интервала дат между p_from_date и p_to_date используйте цикл WHILE. */

CREATE OR REPLACE FUNCTION get_weekends_count(p_from_date date, p_to_date date)
    RETURNS integer
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_current_date  date;
    v_weekend_count integer;
BEGIN
    v_weekend_count := 0;
    v_current_date := p_from_date;

    WHILE v_current_date <= p_to_date
        LOOP
            IF EXTRACT(DOW FROM v_current_date) IN (0, 6) THEN
                v_weekend_count := v_weekend_count + 1; -- Increment the weekend count
            END IF;

            v_current_date := v_current_date + INTERVAL '1 day';
        END LOOP;

    RETURN v_weekend_count;
END;
$$;

/* 3. При обновлении приложения «Вело-вжик» произошёл сбой, в результате которого потерялись
рост height и вес mass  некоторых пользователей. Потерянные данные удалось восстановить
в виде json-массива такого вида:
'[
    {"user_id":1, "mass":64, "height":1.60},
    {"user_id":2, "mass":82, "height":1.73}
]'
Напишите анонимный блок для восстановления данных в таблице из входящего массива.
Для преобразования данных в массив используйте конструкцию:
ARRAY (SELECT jsonb_array_elements('строка в формате JSON'::jsonb)) */

DO
$$
    DECLARE
        user_data  jsonb;
        json_input jsonb := '[
        {"user_id":1, "mass":64, "height":1.60},
        {"user_id":2, "mass":82, "height":1.73}
    ]';

    BEGIN
        FOR user_data IN
            SELECT * FROM jsonb_array_elements(json_input)
            LOOP
                UPDATE users
                SET mass   = (user_data ->> 'mass')::numeric,
                    height = (user_data ->> 'height')::numeric
                WHERE id = (user_data ->> 'user_id')::integer;

                RAISE NOTICE 'Updated user_id: %, mass: %, height: %',
                    (user_data ->> 'user_id')::integer,
                    (user_data ->> 'mass')::numeric,
                    (user_data ->> 'height')::numeric;
            END LOOP;
    END
$$;

/* 4. Чтобы протестировать приложение «Вело-вжик», нужно внести тестовые записи в таблицу
user_groups. Таблица состоит из двух полей: id — типа serial и group_name — типа text.
Напишите код анонимного блока, который заполнит поле с группами тестовыми
названиями: «Тестовая группа 5», «Тестовая группа 10», «Тестовая группа 15». Используйте ц
икл FOR для интервала целых чисел. */

DO
$$
    BEGIN
        FOR i IN 5..15 BY 5
            LOOP
                INSERT INTO user_groups (group_name)
                VALUES ('Тестовая группа ' || i);
            END LOOP;
    END
$$;



