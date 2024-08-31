CREATE OR REPLACE FUNCTION get_bmi_status(p_user_id integer)
    RETURNS text
    LANGUAGE plpgsql
AS
$$
    -- определим переменную _bmi для хранения вычисляемого значения
-- типа real, так как значение может быть дробным числом
DECLARE
    _bmi real;
BEGIN
    -- выполним запрос к таблице users, вычисляющий значение BMI
    -- и сохраняющий результат в переменной _bmi
    SELECT mass / (height * height)
    INTO _bmi
    FROM users
    WHERE id = p_user_id;

    -- с помощью условного оператора вернём
    -- значение, соответствующее полученному результату
    IF _bmi < 18.5 THEN
        RETURN 'Низкий ИМТ: ' || _bmi;
    ELSEIF _bmi < 25 THEN
        RETURN 'Средний ИМТ: ' || _bmi;
    ELSEIF _bmi < 30 THEN
        RETURN 'ИМТ выше среднего: ' || _bmi;
    ELSE
        RETURN 'Высокий ИМТ: ' || _bmi;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION get_bmi_status(p_user_id integer)
    RETURNS text
    LANGUAGE plpgsql
AS
$$
DECLARE
    _bmi REAL;
BEGIN
    SELECT mass / (height * height)
    INTO _bmi
    FROM users
    WHERE id = p_user_id;

    CASE
        WHEN _bmi < 18.5 THEN RETURN 'Низкий ИМТ: ' || _bmi;
        WHEN _bmi < 25 THEN RETURN 'Средний ИМТ: ' || _bmi;
        WHEN _bmi < 30 THEN RETURN 'ИМТ выше среднего: ' || _bmi;
        ELSE RETURN 'Высокий ИМТ: ' || _bmi;
        END CASE;
END;
$$;

SELECT get_bmi_status(8);