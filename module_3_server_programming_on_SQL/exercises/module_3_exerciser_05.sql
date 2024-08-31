/* 1.
Чем более интенсивно велосипедист крутит педали, тем больше калорий он сжигает. Например,
на умеренную интенсивность езды со скоростью до 25 км/ч тратится в среднем 350 калорий в час.
Чуть более интенсивная езда со скоростью 25–30 км/ч в среднем сжигает уже 600 калорий в час.
Напишите функцию training_energy_consumption, которая:

    принимает скорость (p_speed numeric) и время тренировки в часах (p_time numeric)
    возвращает количество энергии, потраченной на тренировку.

Используйте оператор ветвления IF. */

CREATE OR REPLACE FUNCTION training_energy_consumption(
    p_speed numeric,
    p_time numeric
)
    RETURNS numeric
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_calories_per_hour numeric;
    v_total_energy      numeric;
BEGIN
    IF p_speed < 25 THEN
        v_calories_per_hour := 350;
    ELSIF p_speed >= 25 AND p_speed <= 30 THEN
        v_calories_per_hour := 600;
    ELSE
        v_calories_per_hour := 800;
    END IF;

    v_total_energy := v_calories_per_hour * p_time;

    RETURN v_total_energy;
END;
$$;


/* 2. При выполнении тренировок важно следить за частотой пульса и не допускать превышения
екомендуемого максимального значения пульса. Максимальное значение пульса зависит от пола
и возраста. Например, если возраст составляет xx лет, то рекомендуемый максимальный показатель
можно рассчитать по формуле:
    для мужчин: 220 – xx ударов в минуту,
    для женщин: 196 – xx ударов в минуту.
Напишите функцию max_heart_rate, которая принимает два параметра: возраст (p_age integer)
и пол (p_gender char(1)) и возвращает:
    максимально допустимое значение пульса для мужчин, если параметр p_gender равен
        М (латинская буква);
    значение для женщин, если параметр p_gender равен F (латинская буква);
    выдаёт исключение, если пол указан неверно.
В решении используйте оператор выбора CASE. */

CREATE OR REPLACE FUNCTION max_heart_rate(
    p_age integer,
    p_gender char(1)
)
    RETURNS integer
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_max_heart_rate integer;
BEGIN
    v_max_heart_rate := CASE
                            WHEN p_gender = 'M' THEN 220 - p_age
                            WHEN p_gender = 'F' THEN 196 - p_age
                            ELSE NULL
        END;

    IF v_max_heart_rate IS NULL THEN
        RAISE EXCEPTION 'Invalid gender: %', p_gender;
    END IF;

    RETURN v_max_heart_rate;
END;
$$;
