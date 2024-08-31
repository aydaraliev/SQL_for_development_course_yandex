/* 1. «Гипер-Хипер» развивается и выходит на зарубежные рынки. Поэтому в таблицу товаров
добавили цены в тенге price_kzt и белорусских рублях price_byn, а также создали новую таблицу
currencies с актуальными курсами валют:
currency	rate	name
KZT	        4.76	Казахстанский тенге
BYN	        0.033	Белорусский рубль
Напишите триггерную функцию update_product_prices, которая будет пересчитывать значение колонок
price_kzt и price_byn в таблице products при изменении курса соответствующих валют. Цена в
валюте равна цене в рублях, умноженной на курс валюты.
После напишите триггер update_price, вызывающий функцию update_product_prices после каждого
обновления курса валют. */

CREATE OR REPLACE FUNCTION update_product_prices()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$$
BEGIN
    IF NEW.currency = 'KZT' THEN
        UPDATE products
        SET price_kzt = price_rub * NEW.rate;
    END IF;

    IF NEW.currency = 'BYN' THEN
        UPDATE products
        SET price_byn = price_rub * NEW.rate;
    END IF;

    RETURN NULL;
END;
$$;

CREATE TRIGGER update_price
    AFTER UPDATE
    ON currencies
    FOR EACH ROW
EXECUTE FUNCTION update_product_prices();

/* 2. Менеджмент «Гипер-Хипера» задумал провести редизайн онлайн-магазина и добавить на сайт
виджет с курсами валют и их изменениями. Для реализации этой идеи нужно внести несколько
изменений в базу данных.
Сперва добавьте поля в таблицу currencies:
    change_rate типа numeric(5,2) — хранит процент изменения курса валюты.
    updated_at типа timestamp — хранит временную метку последнего изменения.
Затем напишите триггерную функцию update_change_rate, сохраняющую эти данные.
Значение change_rate рассчитывается по формуле:
(новый курс валюты - старый курс валюты) / старый курс валюты * 100. В поле updated_at
заносится временная метка последнего изменения. */

ALTER TABLE currencies
    ADD COLUMN change_rate NUMERIC(5, 2),
    ADD COLUMN updated_at  TIMESTAMP;

CREATE OR REPLACE FUNCTION update_change_rate()
    RETURNS TRIGGER AS
$$
BEGIN
    NEW.change_rate := ((NEW.rate - OLD.rate) / OLD.rate) * 100;

    NEW.updated_at := CURRENT_TIMESTAMP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_currency_rate
    BEFORE UPDATE
    ON currencies
    FOR EACH ROW
    WHEN (OLD.rate IS DISTINCT FROM NEW.rate)
EXECUTE FUNCTION update_change_rate();

/* 3. Менеджеры по закупкам попросили автоматизировать обновление остатков товара при внесении
заказов в таблицу orders.
Напишите код триггерной функции update_products_amount. Вот что она делает с остатком
товара — поле amount в таблице products:
    Уменьшает остаток товара при добавлении строк в таблицу заказов orders.
    Увеличивает остаток товара при удалении строк из таблицы заказов orders.
    Изменяет остаток товара при изменении количества товара в заказе.
Затем напишите триггер orders_after_change, вызывающий функцию после любого изменения
таблицы orders. */

CREATE OR REPLACE FUNCTION update_products_amount()
    RETURNS TRIGGER AS
$$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE products
        SET amount = amount - NEW.amount
        WHERE id = NEW.product_id;

    ELSIF TG_OP = 'DELETE' THEN
        UPDATE products
        SET amount = amount + OLD.amount
        WHERE id = OLD.product_id;

    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE products
        SET amount = amount + (OLD.amount - NEW.amount)
        WHERE id = NEW.product_id;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER orders_after_change
    AFTER INSERT OR DELETE OR UPDATE
    ON orders
    FOR EACH ROW
EXECUTE FUNCTION update_products_amount();


