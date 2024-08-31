/* Вы работаете в растущей IT-компании Dream Big. Специализация компании — разработка
программного обеспечения на заказ. Десятки сотрудников каждый день без устали трудятся над
самыми разнообразными проектами: от скромных приложений до грандиозных платформ.
Вы попивали кофе во время перерыва, когда ворвался взъерошенный тимлид Арсений с новой
горящей задачей — нужно автоматизировать некоторые процессы в Dream Big для внутренней
системы управления персоналом под кодовым названием «Всё записано». В компании есть база
данных PostgreSQL с детализированной информацией о сотрудниках, проектах и логах времени.
Сейчас структуре БД и механизмам запросов не хватает гибкости и производительности. Кроме
того, политика безопасности проекта гласит: все запросы выполняются строго через функции и
процедуры, сырые запросы к таблицам — запрещены.
Ваша задача — создать ряд хранимых процедур и функций, которые оптимизируют и автоматизируют
процессы извлечения, анализа и изменения данных. Арсений предполагает, что это позволит
менеджерам по персоналу и бухгалтерии Dream Big быстро получать отчёты, анализировать
рабочие часы и корректировать данные в режиме реального времени.
Протестируйте гипотезу Арсения. */

/* Задание 1
В Dream Big ежемесячно оценивают производительность сотрудников. В результате бывает, кому-то
повышают, а изредка понижают почасовую ставку. Напишите хранимую процедуру
update_employees_rate, которая обновляет почасовую ставку сотрудников на определённый процент.
При понижении ставка не может быть ниже минимальной — 500 рублей в час. Если по расчётам
выходит меньше, устанавливают минимальную ставку.
На вход процедура принимает строку в формате json:
   [
    -- uuid сотрудника                                      процент изменения ставки
    {"employee_id": "6bfa5e20-918c-46d0-ab18-54fc61086cba", "rate_change": 10},
    -- -- --
    {"employee_id": "5a6aed8f-8f53-4931-82f4-66673633f2a8", "rate_change": -5}
] */

-- Процедура
CREATE OR REPLACE PROCEDURE update_employees_rate(rate_changes_json json)
    LANGUAGE plpgsql
AS
$$
DECLARE
    rate_change_record jsonb;
    employee_id        UUID;
    rate_change        NUMERIC;
    current_rate       NUMERIC;
    new_rate           NUMERIC;
BEGIN
    FOR rate_change_record IN
        SELECT * FROM jsonb_array_elements(rate_changes_json::jsonb)
        LOOP
            employee_id := (rate_change_record ->> 'employee_id')::UUID;
            rate_change := (rate_change_record ->> 'rate_change')::NUMERIC;

            SELECT rate
            INTO current_rate
            FROM employees
            WHERE id = employee_id;

            new_rate := current_rate * (1 + rate_change / 100);

            IF new_rate < 500 THEN
                new_rate := 500;
            END IF;

            UPDATE employees
            SET rate = new_rate
            WHERE id = employee_id;
        END LOOP;

    COMMIT;
END;
$$;

-- Исходная ставка
SELECT *
FROM employees
WHERE id IN ('dd0ba8dd-6c75-437c-9c68-824971ccc078',
             'f0e2ca99-3863-4cbf-a308-1939195d0df8');

-- Вызываем процедуру
CALL update_employees_rate(
        '[
          {
            "employee_id": "dd0ba8dd-6c75-437c-9c68-824971ccc078",
            "rate_change": 10
          },
          {
            "employee_id": "f0e2ca99-3863-4cbf-a308-1939195d0df8",
            "rate_change": -5
          }
        ]'::json
     );

-- Проверяем что почасовая ставка обновилась
SELECT *
FROM employees
WHERE id IN ('dd0ba8dd-6c75-437c-9c68-824971ccc078',
             'f0e2ca99-3863-4cbf-a308-1939195d0df8');

/* Задание 2
С ростом доходов компании и учётом ежегодной инфляции Dream Big индексирует зарплату всем
сотрудникам. Напишите хранимую процедуру indexing_salary, которая повышает зарплаты всех
сотрудников на определённый процент. Процедура принимает один целочисленный параметр — процент
индексации p. Сотрудникам, которые получают зарплату по ставке ниже средней относительно всех
сотрудников до индексации, начисляют дополнительные 2% (p + 2). Ставка остальных сотрудников
увеличивается на p%. Зарплата хранится в БД в типе данных integer, поэтому если в результате
повышения зарплаты образуется дробное число, его нужно округлить до целого. */

-- Процедура
CREATE OR REPLACE PROCEDURE indexing_salary(p INTEGER)
    LANGUAGE plpgsql
AS
$$
DECLARE
    avg_hourly_rate NUMERIC;
BEGIN
    SELECT AVG(rate)
    INTO avg_hourly_rate
    FROM employees;

    UPDATE employees
    SET rate = ROUND(
            CASE
                WHEN rate < avg_hourly_rate THEN rate * (1 + (p + 2) / 100.0)
                ELSE rate * (1 + p / 100.0)
                END
               )::INTEGER;

    COMMIT;
END;
$$;

-- Почасовая ставка до повышения
SELECT *
FROM employees
LIMIT 5;

-- Вызов процедуры
CALL indexing_salary(15);

-- Почасовая ставка после повышения
SELECT *
FROM employees
LIMIT 5;

/* Задание 3
Завершая проект, нужно сделать два действия в системе учёта:
    Изменить значение поля is_active в записи проекта на false — чтобы рабочее время по
     этому проекту больше не учитывалось.
    Посчитать бонус, если он есть — то есть распределить неизрасходованное время между всеми
     членами команды проекта. Неизрасходованное время — это разница между временем, которое
     выделили на проект (estimated_time), и фактически потраченным. Если поле estimated_time
     не задано, бонусные часы не распределятся. Если отработанных часов нет — расчитывать
     бонус не нужно.
Разберёмся с бонусом.
Если в момент закрытия проекта estimated_time:
    не NULL,
    больше суммы всех отработанных над проектом часов,
всем членам команды проекта начисляют бонусные часы.
Размер бонуса считают так: 75% от сэкономленных часов делят на количество участников проекта,
но не более 16 бонусных часов на сотрудника. Дробные значения округляют в меньшую сторону
(например, 3.7 часа округляют до 3). Рабочие часы заносят в логи с текущей датой.
Например, если на проект запланировали 100 часов, а сделали его за 30 — 3/4 от сэкономленных
70 часов распределят бонусом между участниками проекта.
Создайте пользовательскую процедуру завершения проекта close_project. Если проект уже закрыт,
процедура должна вернуть ошибку без начисления бонусных часов. */

-- Процедура
CREATE OR REPLACE PROCEDURE close_project(project_id UUID)
    LANGUAGE plpgsql
AS
$$
DECLARE
    total_logged_time     NUMERIC;
    p_estimated_time      NUMERIC;
    unused_time           NUMERIC;
    bonus_time_per_member NUMERIC;
    project_members_count INTEGER;
BEGIN
    IF EXISTS (SELECT 1 FROM projects WHERE id = project_id AND is_active = false) THEN
        RAISE EXCEPTION 'The project is already closed.';
    END IF;

    SELECT estimated_time
    INTO p_estimated_time
    FROM projects
    WHERE id = project_id;

    IF p_estimated_time IS NULL THEN
        UPDATE projects
        SET is_active = false
        WHERE id = project_id;
        RETURN;
    END IF;

    SELECT COALESCE(SUM(work_hours), 0)
    INTO total_logged_time
    FROM logs
    WHERE logs.project_id = close_project.project_id;

    IF total_logged_time = 0 THEN
        UPDATE projects
        SET is_active = false
        WHERE id = project_id;
        RETURN;
    END IF;

    unused_time := p_estimated_time - total_logged_time;

    IF unused_time <= 0 THEN
        UPDATE projects
        SET is_active = false
        WHERE id = project_id;
        RETURN;
    END IF;

    SELECT COUNT(DISTINCT employee_id)
    INTO project_members_count
    FROM logs
    WHERE logs.project_id = close_project.project_id;

    bonus_time_per_member := FLOOR((unused_time * 0.75) / project_members_count);

    IF bonus_time_per_member > 16 THEN
        bonus_time_per_member := 16;
    END IF;

    IF bonus_time_per_member > 0 THEN
        INSERT INTO logs (employee_id, project_id, work_hours, work_date)
        SELECT DISTINCT l.employee_id, p.id, bonus_time_per_member, CURRENT_DATE
        FROM projects p
                 JOIN logs l ON p.id = l.project_id
        WHERE p.id = close_project.project_id;
    END IF;

    UPDATE projects
    SET is_active = false
    WHERE id = project_id;

    COMMIT;
END;
$$;

-- Проверка на закрытом проекте is_active = false. Закомменчено что-бы проект запускался.
-- CALL close_project('aefb8a8e-ecf7-4eea-a08e-2d25d4f43efa');

-- Проверка на неподсчитанном количестве часов estimated_time = NULL
INSERT INTO projects (name, estimated_time, is_active)
VALUES ('Тестовый проект 1', NULL, true);

UPDATE projects
SET is_active = true
WHERE id = '7849ff16-bc76-4ef7-aa41-b8335bbbb618';

CALL close_project('7849ff16-bc76-4ef7-aa41-b8335bbbb618');

SELECT *
FROM projects
WHERE id = '7849ff16-bc76-4ef7-aa41-b8335bbbb618';

-- Проверка на кейс когда отработано больше(или столько же) часов сколько указано
-- в estimated_time. Используем уже созданный проект "Доставка цветов".
INSERT INTO employees (id, name, email, rate)
VALUES ('e94e2c03-8996-4ce9-804b-b27ee27da14d', 'Тестовый работник 1', 'test@example.com', 500);

INSERT INTO logs (employee_id, project_id, work_date, work_hours)
VALUES ('e94e2c03-8996-4ce9-804b-b27ee27da14d',
        '778e5574-45ec-4be0-91eb-579146273232',
        CURRENT_DATE,
        850);

UPDATE projects
SET is_active = true
WHERE id = '778e5574-45ec-4be0-91eb-579146273232';

CALL close_project('778e5574-45ec-4be0-91eb-579146273232');

SELECT *
FROM projects
WHERE id = '778e5574-45ec-4be0-91eb-579146273232';

-- Проверка на начисление бонусов на проекте "Навигатор"
SELECT *
FROM projects
WHERE id = '4abb5b99-3889-4c20-a575-e65886f266f9';

SELECT SUM(work_hours)
FROM logs
WHERE project_id = '4abb5b99-3889-4c20-a575-e65886f266f9';

UPDATE projects
SET is_active = TRUE
WHERE id = '4abb5b99-3889-4c20-a575-e65886f266f9';

CALL close_project('4abb5b99-3889-4c20-a575-e65886f266f9');

SELECT *
FROM logs
WHERE project_id = '4abb5b99-3889-4c20-a575-e65886f266f9';

/* Задание 4
Напишите процедуру log_work для внесения отработанных сотрудниками часов. Процедура добавляет
новые записи о работе сотрудников над проектами. Процедура принимает id сотрудника, id
проекта, дату и отработанные часы и вносит данные в таблицу logs. Если проект завершён,
добавить логи нельзя — процедура должна вернуть ошибку Project closed. Количество
залогированных часов может быть в этом диапазоне: от 1 до 24 включительно — нельзя внести
менее 1 часа или больше 24. Если количество часов выходит за эти пределы, необходимо вывести
предупреждение о недопустимых данных и остановить выполнение процедуры. Запись помечается
флагом required_review, если:
    залогированно более 16 часов за один день — Dream Big заботится о здоровье сотрудников;
    запись внесена будущим числом;
    запись внесена более ранним числом, чем на неделю назад от текущего дня — например, если
     сегодня 10.04.2023, все записи старше 3.04.2023 получат флажок. */

-- Процедура
CREATE OR REPLACE PROCEDURE log_work(
    employee_id UUID,
    project_id UUID,
    work_date DATE,
    work_hours NUMERIC
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    project_active BOOLEAN;
    review_flag    BOOLEAN := FALSE;
BEGIN
    SELECT is_active
    INTO project_active
    FROM projects
    WHERE id = project_id;

    IF project_active = FALSE THEN
        RAISE EXCEPTION 'Project closed';
    END IF;

    IF work_hours < 1 OR work_hours > 24 THEN
        RAISE EXCEPTION 'Invalid number of hours. Must be between 1 and 24.';
    END IF;

    IF work_hours > 16 THEN
        review_flag := TRUE;
    END IF;

    IF work_date > CURRENT_DATE THEN
        review_flag := TRUE;
    END IF;

    IF work_date < CURRENT_DATE - INTERVAL '7 days' THEN
        review_flag := TRUE;
    END IF;

    INSERT INTO logs (employee_id, project_id, work_hours, work_date, required_review)
    VALUES (log_work.employee_id, log_work.project_id, log_work.work_hours,
            log_work.work_date, review_flag);

    COMMIT;
END;
$$;

-- Проверка на завершенный проект. Проект "Выгул собак", работник Зайцев. Закомменчено что-бы
-- код исполнялся без ошибок.
-- CALL log_work('91c05d36-c690-4742-bcf4-6bef86fc36d3',
--               'aefb8a8e-ecf7-4eea-a08e-2d25d4f43efa',
--               '2024-08-10',
--               15
--      );

-- Проверка на диапозон залоггированных часов. Проект Такси, работник Зайцев. Закомменчено что-бы
-- -- код исполнялся без ошибок.
-- CALL log_work('91c05d36-c690-4742-bcf4-6bef86fc36d3',
--               'c330ad5f-7c34-4aae-b8dc-3e95f2ec07c3',
--               '2024-08-10',
--               25
--      );

-- Проверка на логгирование более 16 часов в день. Проект Такси, работник Зайцев
CALL log_work('91c05d36-c690-4742-bcf4-6bef86fc36d3',
              'c330ad5f-7c34-4aae-b8dc-3e95f2ec07c3',
              '2024-08-10',
              17
     );

SELECT *
FROM LOGS
WHERE employee_id = '91c05d36-c690-4742-bcf4-6bef86fc36d3'
  AND required_review = TRUE;

-- Проверка на внесение будущим числом. Проект Такси, работник Зайцев
CALL log_work('91c05d36-c690-4742-bcf4-6bef86fc36d3',
              'c330ad5f-7c34-4aae-b8dc-3e95f2ec07c3',
              '2024-08-16',
              15
     );

SELECT *
FROM LOGS
WHERE employee_id = '91c05d36-c690-4742-bcf4-6bef86fc36d3'
  AND required_review = TRUE;

-- Проверка на внесение более 1й недели назад. Проект Такси, работник Зайцев
CALL log_work('91c05d36-c690-4742-bcf4-6bef86fc36d3',
              'c330ad5f-7c34-4aae-b8dc-3e95f2ec07c3',
              '2024-08-03',
              14
     );

SELECT *
FROM LOGS
WHERE employee_id = '91c05d36-c690-4742-bcf4-6bef86fc36d3'
  AND required_review = TRUE;

/* Задание 5
Чтобы бухгалтерия корректно начисляла зарплату, нужно хранить историю изменения почасовой
ставки сотрудников. Создайте отдельную таблицу employee_rate_history с такими столбцами:
    id — id записи,
    employee_id — id сотрудника,
    rate — почасовая ставка сотрудника,
    from_date — дата назначения новой ставки.
Внесите в таблицу текущие данные всех сотрудников. В качестве from_date используйте дату
основания компании: '2020-12-26'. Напишите триггерную функцию save_employee_rate_history и
триггер change_employee_rate. При добавлении сотрудника в таблицу employees и изменении
ставки сотрудника триггер автоматически вносит запись в таблицу employee_rate_history из
трёх полей: id сотрудника, его ставки и текущей даты. */

-- Создание и заполнение таблицы, триггерная функция, триггер
CREATE TABLE employee_rate_history
(
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID    NOT NULL,
    rate        NUMERIC NOT NULL,
    from_date   DATE    NOT NULL
);

INSERT INTO employee_rate_history (employee_id, rate, from_date)
SELECT id, rate, '2020-12-26'::DATE
FROM employees;

CREATE OR REPLACE FUNCTION save_employee_rate_history()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$$
BEGIN
    INSERT INTO employee_rate_history (employee_id, rate, from_date)
    VALUES (NEW.id, NEW.rate, CURRENT_DATE);

    RETURN NEW;
END;
$$;

CREATE TRIGGER change_employee_rate
    AFTER INSERT OR UPDATE OF rate
    ON employees
    FOR EACH ROW
EXECUTE FUNCTION save_employee_rate_history();

-- Проверка триггера на добавление строк в таблицу с историей
SELECT COUNT(DISTINCT employee_id)
FROM employee_rate_history;

SELECT COUNT(*)
FROM employee_rate_history;

-- Меняем почасовой рейт у Зайцева
UPDATE employees
SET rate = 5000
WHERE id = '91c05d36-c690-4742-bcf4-6bef86fc36d3';

SELECT COUNT(*)
FROM employee_rate_history;

SELECT *
FROM employee_rate_history
WHERE employee_id = '91c05d36-c690-4742-bcf4-6bef86fc36d3';

/* Задание 6
После завершения каждого проекта Dream Big проводит корпоративную вечеринку, чтобы
отпраздновать очередной успех и поощрить сотрудников. Тех, кто посвятил проекту больше
всего часов, награждают премией «Айтиголик» — они получают почётные грамоты и ценные
подарки от заказчика.
Чтобы вычислить айтиголиков проекта, напишите функцию best_project_workers.
Функция принимает id проекта и возвращает таблицу с именами трёх сотрудников, которые
залогировали максимальное количество часов в этом проекте. Результирующая таблица состоит
из двух полей: имени сотрудника и количества часов, отработанных на проекте. */

--Функция
CREATE OR REPLACE FUNCTION best_project_workers(project_uuid UUID)
    RETURNS TABLE
            (
                employee_name TEXT,
                total_hours   NUMERIC
            )
AS
$$
BEGIN
    RETURN QUERY
        SELECT e.name                     AS employee_name,
               SUM(l.work_hours)::NUMERIC AS total_hours
        FROM employees e
                 JOIN
             logs l ON e.id = l.employee_id
        WHERE l.project_id = project_uuid
        GROUP BY e.name
        ORDER BY total_hours DESC
        LIMIT 3;
END;
$$ LANGUAGE plpgsql;

--Проверка
SELECT *
FROM best_project_workers('c330ad5f-7c34-4aae-b8dc-3e95f2ec07c3');

SELECT *
FROM best_project_workers('35647af3-2aac-45a0-8d76-94bc250598c2');

SELECT *
FROM best_project_workers('2dfffa75-7cd9-4426-922c-95046f3d06a0');

/* Задание 7
К вам заглянул утомлённый главный бухгалтер Марк Захарович с лёгкой синевой под глазами и
попросил как-то автоматизировать расчёт зарплаты, пока бухгалтерия не испустила дух.
Напишите для бухгалтерии функцию calculate_month_salary для расчёта зарплаты за месяц.
Функция принимает в качестве параметров даты начала и конца месяца и возвращает результат
в виде таблицы с четырьмя полями: id (сотрудника), employee (имя сотрудника), worked_hours
и salary. Процедура суммирует все залогированные часы за определённый месяц и умножает на
актуальную почасовую ставку сотрудника. Исключения — записи с флажками required_review и
is_paid. Если суммарно по всем проектам сотрудник отработал более 160 часов в месяц, все
часы свыше 160 оплатят с коэффициентом 1.25. */

CREATE OR REPLACE FUNCTION calculate_month_salary(start_date DATE, end_date DATE)
    RETURNS TABLE
            (
                id           UUID,
                employee     TEXT,
                worked_hours NUMERIC,
                salary       NUMERIC
            )
AS
$$
BEGIN
    RETURN QUERY
        SELECT e.id,
               e.name                     AS employee,
               SUM(l.work_hours)::NUMERIC AS worked_hours,
               (CASE
                    WHEN SUM(l.work_hours) > 160 THEN
                        160 * r.rate + (SUM(l.work_hours) - 160) * r.rate * 1.25
                    ELSE
                        SUM(l.work_hours) * r.rate
                   END)::NUMERIC          AS salary
        FROM employees e
                 JOIN
             logs l ON e.id = l.employee_id
                 JOIN
             employee_rate_history r ON e.id = r.employee_id
        WHERE l.work_date BETWEEN start_date AND end_date
          AND l.required_review = false
          AND l.is_paid = false
          AND r.from_date <= end_date
        GROUP BY e.id, e.name, r.rate
        ORDER BY e.name;
END;
$$ LANGUAGE plpgsql;

-- Простейшая проверка
SELECT *
FROM calculate_month_salary('2023-10-01', '2023-10-31');

-- Проверка на то сработает ли перерасчёт зарплаты если в течение месяца менялась
-- почасовая ставка

UPDATE employees
SET rate = 700
WHERE id = 'e94e2c03-8996-4ce9-804b-b27ee27da14d';

INSERT INTO logs (employee_id, project_id, work_hours, work_date, required_review, is_paid)
VALUES ('e94e2c03-8996-4ce9-804b-b27ee27da14d', '35647af3-2aac-45a0-8d76-94bc250598c2', 8, '2024-08-01', FALSE, FALSE),
       ('e94e2c03-8996-4ce9-804b-b27ee27da14d', '35647af3-2aac-45a0-8d76-94bc250598c2', 8, '2024-08-02', FALSE, FALSE),
       ('e94e2c03-8996-4ce9-804b-b27ee27da14d', '35647af3-2aac-45a0-8d76-94bc250598c2', 8, '2024-08-03', FALSE, FALSE),
       ('e94e2c03-8996-4ce9-804b-b27ee27da14d', '35647af3-2aac-45a0-8d76-94bc250598c2', 8, '2024-08-04', FALSE, FALSE),
       ('e94e2c03-8996-4ce9-804b-b27ee27da14d', '35647af3-2aac-45a0-8d76-94bc250598c2', 8, '2024-08-05', FALSE, FALSE),
       ('e94e2c03-8996-4ce9-804b-b27ee27da14d', '35647af3-2aac-45a0-8d76-94bc250598c2', 8, '2024-08-06', FALSE, FALSE),
       ('e94e2c03-8996-4ce9-804b-b27ee27da14d', '35647af3-2aac-45a0-8d76-94bc250598c2', 8, '2024-08-07', FALSE, FALSE),
       ('e94e2c03-8996-4ce9-804b-b27ee27da14d', '35647af3-2aac-45a0-8d76-94bc250598c2', 8, '2024-08-08', FALSE, FALSE);

SELECT *
FROM calculate_month_salary('2024-08-01', '2024-08-31');

/* Записи для тестового работника 1 и Зайцева дублируются поскольку их почасовая ставка
менялась в течение одного месяца. В задании не сказано как обрабатывать этот случай,
поэтому сделал на своё усмотрение. */

/* Задание 6* (необязательное)
Это задание — необязательно для сдачи проекта. Вы можете по желанию — пропустить его или
сделать и получить обратную связь от ревьюера. Доработайте функцию best_project_workers.
Если обнаружится несколько сотрудников с одинаковым количеством залогированных часов,
первым становится тот, кто залогировал больше дней. Если и этот параметр совпадёт,
сотрудники в списке выводятся в рандомном порядке. Максимальное количество человек в
списке — три. */

-- Функция
CREATE OR REPLACE FUNCTION best_project_workers(project_uuid UUID)
    RETURNS TABLE
            (
                employee_name TEXT,
                total_hours   NUMERIC
            )
AS
$$
BEGIN
    RETURN QUERY
        SELECT e.name                     AS employee_name,
               SUM(l.work_hours)::NUMERIC AS total_hours
        FROM employees e
                 JOIN
             logs l ON e.id = l.employee_id
        WHERE l.project_id = project_uuid
        GROUP BY e.name
        ORDER BY total_hours DESC,
                 COUNT(DISTINCT l.work_date) DESC,
                 RANDOM()
        LIMIT 3;
END;
$$ LANGUAGE plpgsql;

-- Проверка
INSERT INTO employees (id, name, email, rate)
VALUES ('1f91a5b0-cdf9-4b8e-8b2e-6e5d4d39a9a7', 'Employee 1', 'employee1@example.com', 50000),
       ('2a37e48c-b0d5-4f6d-b1e8-4edfa539d345', 'Employee 2', 'employee2@example.com', 50000),
       ('345db2c5-d57c-4e82-8236-8afceddf5ab6', 'Employee 3', 'employee3@example.com', 50000),
       ('4b3f8d92-06be-4c53-92d2-89599b9b96b5', 'Employee 4', 'employee4@example.com', 50000),
       ('52f8f9cc-793b-4f39-a9b8-2ad5d01a0bce', 'Employee 5', 'employee5@example.com', 50000);

INSERT INTO logs (employee_id, project_id, work_hours, work_date, required_review, is_paid)
VALUES ('1f91a5b0-cdf9-4b8e-8b2e-6e5d4d39a9a7', '7164736e-af27-49b8-aec2-183fe85d0295', 8, '2024-08-10', FALSE, FALSE),
       ('2a37e48c-b0d5-4f6d-b1e8-4edfa539d345', '7164736e-af27-49b8-aec2-183fe85d0295', 8, '2024-08-10', FALSE, FALSE),
       ('345db2c5-d57c-4e82-8236-8afceddf5ab6', '7164736e-af27-49b8-aec2-183fe85d0295', 8, '2024-08-10', FALSE, FALSE),
       ('4b3f8d92-06be-4c53-92d2-89599b9b96b5', '7164736e-af27-49b8-aec2-183fe85d0295', 8, '2024-08-10', FALSE, FALSE),
       ('52f8f9cc-793b-4f39-a9b8-2ad5d01a0bce', '7164736e-af27-49b8-aec2-183fe85d0295', 8, '2024-08-10', FALSE, FALSE);

SELECT *
FROM best_project_workers('7164736e-af27-49b8-aec2-183fe85d0295');

-- Случайная сортировка отрабатывает, значит сортировка по часам и по дням тоже должна
-- работать.
