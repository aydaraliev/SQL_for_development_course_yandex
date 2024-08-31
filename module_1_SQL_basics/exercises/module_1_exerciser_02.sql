/* 1. Администрация магазина решила создать свою сеть выдачи заказов. Вам нужно создать
   таблицу для регистрации пунктов выдачи service_points с такими полями:
id — первичный ключ с автоинкрементом.
name — текст, не пустое.
email — текст, не пустое.
phone — текст, не пустое.
address — текст, не пустое.
manager — имя управляющего, текст, не пустое.
opens_at — время открытия, не пустое.
closes_at — время закрытия, не пустое.
created_at — значение по умолчанию — текущая временная метка. */

create table service_points
(
    id         SERIAL PRIMARY KEY,
    name       TEXT NOT NULL,
    email      TEXT NOT NULL,
    phone      TEXT NOT NULL,
    address    TEXT NOT NULL,
    manager    TEXT NOT NULL,
    opens_at   TIME NOT NULL,
    closes_at  TIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


/* 2. Большая часть пунктов выдачи работает семь дней в неделю, но часть из них закрывается
   на выходные. Напишите запрос, который добавит к уже существующей таблице service_points
   новый столбец days_off. Выберите такой тип столбца, чтобы в нём можно было указать выходной
   в текстовом формате, например «Сб, Вс» или «Воскресенье». Столбец может быть пустым (NULL),
   если пункт работает без выходных. */

CREATE TABLE service_points
(
    id         SERIAL PRIMARY KEY,
    name       TEXT NOT NULL,
    email      TEXT NOT NULL,
    phone      TEXT NOT NULL,
    address    TEXT NOT NULL,
    manager    TEXT NOT NULL,
    opens_at   TIME NOT NULL,
    closes_at  TIME NOT NULL,
    created_at TIMESTAMP DEFAULT current_timestamp
);

/* не изменяйте код выше этого комментария,
своё решение напишите ниже. */

ALTER TABLE service_points
    ADD COLUMN days_off text;

/* 3. В таблице service_points есть колонки opens_at и closes_at с временем открытия и
   закрытия. Чтобы избежать ошибок при внесении данных, добавьте ограничение — чтобы
   время закрытия не могло быть равным или меньшим времени открытия. Назовите ограничение
   check_close_time. */

CREATE TABLE service_points
(
    id         SERIAL PRIMARY KEY,
    name       TEXT NOT NULL,
    email      TEXT NOT NULL,
    phone      TEXT NOT NULL,
    address    TEXT NOT NULL,
    manager    TEXT NOT NULL,
    opens_at   TIME NOT NULL
        CONSTRAINT check_close_time CHECK (opens_at < closes_at),
    closes_at  TIME NOT NULL,
    created_at TIMESTAMP DEFAULT current_timestamp,
    days_off   TEXT
);

/* 4. Пока вы были в отпуске, ваш бухгалтер — он немного знает SQL — попытался доработать
   таблицу поставщиков suppliers и добавить в неё два новых поля: comments — для
   комментариев и debt — для задолженности. Начинание похвальное, но ничего не
   получилось — запрос не сработал. Бухгалтер обратился к вам с просьбой помочь.
   Найдите и исправьте две ошибки в запросе коллеги. */

CREATE TABLE suppliers
(
    id             SERIAL PRIMARY KEY,
    name           TEXT NOT NULL UNIQUE,
    email          TEXT NOT NULL,
    phone          TEXT NOT NULL,
    address        TEXT NOT NULL,
    contact_person TEXT,
    bank_name      TEXT,
    bank_account   TEXT,
    created_at     TIMESTAMP DEFAULT current_timestamp
);

/* не изменяйте код выше этого комментария,
исправьте код запроса ниже так, чтобы добавить
колонки comments и debt к таблице suppliers */

ALTER TABLE suppliers
    ADD COLUMN comments TEXT,
    ADD COLUMN debt     DECIMAL(12, 2);