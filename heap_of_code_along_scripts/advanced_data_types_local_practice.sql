CREATE TABLE drivers
(
    guid           uuid PRIMARY KEY DEFAULT GEN_RANDOM_UUID(),
    driver_name    text,
    driver_license bigint,
    depot_id       integer
);

INSERT INTO drivers (driver_name, driver_license, depot_id)
VALUES ('Иванов Сергей Олегович', 7777123123, 1);

INSERT INTO drivers (guid, driver_name, driver_license, depot_id)
VALUES (GEN_RANDOM_UUID(), 'Земцов Вячеслав Николаевич', '4444567567', NULL);

INSERT INTO drivers (guid, driver_name, driver_license, depot_id)
VALUES ('30bfcb96-afc2-4819-bf97-7c56c863991c',
        'Свиридов Михаил Владимирович',
        9876876876,
        2);

CREATE TABLE depots_economic_report
(
    id            integer PRIMARY KEY,
    depot_id      integer,
    date_begin    date,
    economic_data integer[]
);

INSERT INTO depots_economic_report(id, depot_id, date_begin, economic_data)
VALUES (1, 1, current_date, '{{100, 40}, {200, 85}}');

INSERT INTO depots_economic_report(id, depot_id, date_begin, economic_data)
VALUES (2, 7, current_date, ARRAY [[350, 90], [400, 120]]);

CREATE TABLE array_tests
(
    arr_data integer[]
);

INSERT INTO array_tests(arr_data)
VALUES ('{{{1, 2}, {3, 4}}, {{5, 6}, {7, 8}}}');

SELECT arr_data[2][1][2]
FROM array_tests;

DROP TABLE clients CASCADE;
CREATE TABLE clients
(
    id          integer PRIMARY KEY,
    client_name text,
    phone       text,
    add_phones  text[] -- массив текстовых данных
);

INSERT INTO clients(id, client_name, phone, add_phones)
VALUES (1, 'Лесной Анатолий Игоревич', '71112223344',
        '{"78885556677", "73335556677"}');

UPDATE clients
SET add_phones = add_phones || '{"75553334455"}'
WHERE phone = '71112223344';

UPDATE clients
SET add_phones = '{"72228886655"}' || add_phones
WHERE phone = '71112223344';

INSERT INTO clients(id, client_name, phone, add_phones)
VALUES (2, 'Полевой Александр Павлович', '73332221144',
        ARRAY ['78881112233', '77772224477']);

UPDATE clients
SET add_phones = ARRAY_APPEND(add_phones, '71112223344')
WHERE phone = '73332221144';

UPDATE depots_economic_report
SET economic_data[1][2] = 50
WHERE depot_id = 1;

UPDATE clients
SET add_phones[1:2] = '{"72228880000", "78885550000"}'
WHERE phone = '71112223344';

SELECT *
FROM depots_economic_report
WHERE economic_data[2][1] > 300;

SELECT *
FROM clients
WHERE '72228880000' = ANY (add_phones);

SELECT *
FROM clients
WHERE add_phones && '{"72228880000"}';

SELECT *
FROM depots_economic_report
WHERE 60 < ALL (economic_data);

SELECT *
FROM depots_economic_report
WHERE 60 < ALL (economic_data[1:7][1]);

-- true, все элементы второго массива встречаются в первом
SELECT ARRAY [1, 2, 3, 4, 5] @> ARRAY [5, 3];

-- false, второй массив не содержит все элементы первого
SELECT ARRAY [1, 2, 3, 4, 5] <@ ARRAY [5, 3];

-- true, второй массив содержит все значения первого
SELECT ARRAY [5, 3] <@ ARRAY [1, 2, 3, 4, 5];

SELECT ARRAY_LENGTH(ARRAY [1, 2, 3], 1);

SELECT ARRAY_LENGTH(ARRAY [[1, 2, 3], [4, 5, 6]], 2);

SELECT ARRAY_LENGTH(ARRAY [[1, 2, 3], [4, 5, 6]], 1);

SELECT *, ARRAY_LENGTH(add_phones, 1)
FROM clients;

SELECT *, ARRAY_LENGTH(economic_data, 1)
FROM depots_economic_report;

SELECT ARRAY_TO_STRING(add_phones, ', ')
FROM clients
WHERE id = 1;

UPDATE clients
SET add_phones = STRING_TO_ARRAY('72228880000, 78885550000', ', ')
WHERE id = 1;

CREATE TABLE drivers_schedule
(
    id            serial primary key,
    schedule_date date,
    depot_id      integer,
    driver_guid   uuid
);

INSERT INTO drivers_schedule(depot_id, driver_guid)
SELECT 1,
       unnest(ARRAY [
           '189ec08d-af9c-4f7f-a65c-d12c460d19eb',
           'b9c2e818-bdbb-4cea-bd65-5f3b42782d80',
           'cbdfac9f-5d95-4fbd-a081-11bddcf56dd5'
           ])::uuid;