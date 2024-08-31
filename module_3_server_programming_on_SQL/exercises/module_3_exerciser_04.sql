/* 1. В приложении есть экранная форма с данными о бронировании. Данные для неё получают
через функции, чтобы скрыть от приложения структуру таблиц. Напишите функцию
dog_info_by_booking_id, которая принимает id бронирования в формате integer и возвращает
следующие выходные параметры:
    кличку собаки в формате text в поле p_dog_name.
    название породы собаки в формате text в поле p_breed_name. */

CREATE OR REPLACE FUNCTION dog_info_by_booking_id(
    p_booking_id integer,
    OUT p_dog_name text,
    OUT p_breed_name text
)
    RETURNS record
    LANGUAGE plpgsql
AS
$$
BEGIN
    SELECT d.dog_name, b.breed_name
    INTO p_dog_name, p_breed_name
    FROM bookings bk
             JOIN dogs d ON bk.dog_id = d.id
             JOIN breeds b ON d.breed_id = b.id
    WHERE bk.id = p_booking_id;
END;
$$;

/* 2. В базе данных есть функция, которая рассчитывает KPI сотрудника. Вот её объявление:

CREATE OR REPLACE FUNCTION get_kpi (
    p_staff_id integer,
    in p_department_coeff numeric,
    out p_personal_coeff numeric,
    p_period text default 'month',
    p_use_experience_bonus boolean default false
)
RETURNS record

Что именно происходит внутри функции — неизвестно, но список её параметров выглядит так,
словно функцию много раз дорабатывали, не задумываясь о читабельности кода и хорошем тоне
программирования. Однако сейчас ваша задача — не исправлять функцию, а использовать её.
Вызовите функцию с помощью SELECT, передав значения в эти параметры:

    p_staff_id = 1.
    p_department_coeff = 1.
    p_use_experience_bonus = true.

Значение параметра p_department_coeff передайте в функцию так же, как входной параметр. */

SELECT get_kpi(1, 1, p_use_experience_bonus => true);

/* 3.
Чтобы проанализировать загрузку персонала, потребовалось создать новую функцию. Она
показывает количество собак, за которыми ухаживает определённый сотрудник, за конкретный день.
Напишите такую функцию и назовите её dogs_count_for_staff_by_day(). Функция принимает
следующие параметры:

    id сотрудника, ухаживающего за собаками.
    день, за который производятся вычисления. Значение по умолчанию — текущий день.

Функция возвращает целое число. */

CREATE OR REPLACE FUNCTION dogs_count_for_staff_by_day(
    p_user_id integer,
    p_date date DEFAULT current_date,
    out p_count integer)
    RETURNS integer
    LANGUAGE plpgsql
AS
$$
BEGIN
    SELECT dogs_count
    INTO p_count
    FROM staff_schedule
    WHERE staff_id = p_user_id
      AND day = p_date;
END;
$$ 
