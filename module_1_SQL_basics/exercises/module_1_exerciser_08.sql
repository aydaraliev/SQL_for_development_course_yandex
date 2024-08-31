/* 1. Для оптимизации хранения данных в БД нужно создать таблицу категорий товаров.
Перенесите в неё все уже существующие категории товаров (category) из таблицы товаров
products. Проследите, чтобы не было дубликатов. */

CREATE TABLE product_categories
(
    id   SMALLSERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

INSERT INTO product_categories (name)
SELECT DISTINCT category
FROM products;

/* 2. Вам прислали список поставщиков, которых нужно внести в базу. Часть из них,
   возможно, уже есть в таблице suppliers. Напишите запрос, который добавит новых
   поставщиков, а у тех, что уже есть в базе, обновит адрес, электронную почту и телефон.
Вот список:
Поставщик	            Адрес	                                Электронная почта	Номер телефона
ООО “Солёный персик”	г. Владимир, ул. Белая, д. 3-Б, к. 1	sol.pers@yandex.ru	8674-34-92
ОАО “Простор фантазии”	г. Самара, ул. Тухачевского, д. 231	    office@profant.ru	6985-256-66  */

INSERT INTO suppliers (name, address, email, phone)
VALUES ('ООО “Солёный персик”', 'г. Владимир, ул. Белая, д. 3-Б, к. 1', 'sol.pers@yandex.ru', '8674-34-92'),
       ('ОАО “Простор фантазии”', 'г. Самара, ул. Тухачевского, д. 231', 'office@profant.ru', '6985-256-66')
ON CONFLICT (name)
    DO UPDATE SET address = EXCLUDED.address,
                  email   = EXCLUDED.email,
                  phone   = EXCLUDED.phone;


/* 3. Напишите запрос, который одновременно:
добавит 5% к цене (price) всех товаров в таблице products, страна происхождения
которых (origin_country) — Китай; вернёт список наименований товаров (name), цена
которых изменилась. */

UPDATE products
SET price = price * 1.05
WHERE origin_country = 'Китай'
RETURNING name;


