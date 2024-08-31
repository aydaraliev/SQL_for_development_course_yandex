/*1. Напишите запрос для создания таблицы покупателей customers с такими полями:
id — суррогатный первичный ключ, тип данных integer.
name — имя покупателя, не может быть пустым.
email — адрес электронной почты покупателя, не может быть пустым.
created_at — дата и время добавления записи. Здесь и далее, если в описании таблицы или столбца не написано, что поле не может быть пустым, значит имеется в виду, что поле может принимать NULL.
Для полей name и email строки должны быть любой длины, а поле id автоматически получает возрастающие значения. */

CREATE TABLE customers
(
    id         serial PRIMARY KEY,
    name       text NOT NULL,
    email      text NOT NULL,
    created_at TIMESTAMP
);

/* 2. Менеджер отдела продаж попросил добавить в таблицу колонки: номер телефона (phone) и адрес покупателя (address). Обе колонки должны быть типа text и не допускать ввод пустых значений (NULL). Ещё менеджер попросил добавить колонку birthday для записи даты рождения, но заполнять её не обязательно.
Старший программист посмотрел ваш запрос и посоветовал добавить значение по умолчанию — текущую временную метку для поля created_at.
Напишите новый запрос для создания таблицы customers с учётом новых вводных.
Подсказка */

CREATE TABLE customers
(
    id         SERIAL PRIMARY KEY,
    name       TEXT NOT NULL,
    email      TEXT NOT NULL,
    phone      TEXT NOT NULL,
    address    TEXT NOT NULL,
    birthday   DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

/* 3. Тестировщики нашли баг: покупатель с одним и тем же адресом электронной почты может
   записаться несколько раз. Нужно исправить этот баг. Кроме того, сочетание телефона и
   адреса (именно в таком порядке) также нужно сделать уникальным в пределах всей таблицы.
   Не присваивайте название ограничению уникальности, оно должно сформироваться базой. */

CREATE TABLE customers
(
    id         SERIAL PRIMARY KEY,
    name       TEXT NOT NULL,
    email      TEXT NOT NULL UNIQUE,
    phone      TEXT NOT NULL,
    address    TEXT NOT NULL,
    birthday   DATE,
    created_at TIMESTAMP DEFAULT current_timestamp,
    UNIQUE (phone, address)
);

/* 4. Ваш коллега работал над структурой таблицы заказов orders, но столкнулся с проблемой.
   Его запрос возвращает ошибку и не выполняется. Помогите коллеге найти ошибки в синтаксисе
   запроса. */

CREATE TABLE orders
(
    id          SERIAL PRIMARY KEY,
    customer_id INTEGER       NOT NULL,
    amount      NUMERIC(9, 2) NOT NULL DEFAULT 0,
    paid        BOOLEAN       NOT NULL DEFAULT false,
    created_at  TIMESTAMP              DEFAULT current_timestamp
);

/* 5. Оптимизируйте код коллеги, добавив к нему запрет на отрицательные значения в
   поле amount. */

CREATE TABLE orders
(
    id          SERIAL PRIMARY KEY,
    customer_id INTEGER       NOT NULL,
    amount      NUMERIC(9, 2) NOT NULL DEFAULT 0 CHECK (amount >= 0),
    paid        BOOLEAN       NOT NULL DEFAULT false,
    created_at  TIMESTAMP              DEFAULT current_timestamp
);

