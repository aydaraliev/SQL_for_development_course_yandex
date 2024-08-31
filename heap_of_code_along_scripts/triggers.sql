CREATE MATERIALIZED VIEW goods_by_countries AS
SELECT origin_country,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percent
FROM student.products
GROUP BY origin_country;

CREATE OR REPLACE FUNCTION check_workday()
    RETURNS trigger
    LANGUAGE plpgsql
AS
$$
BEGIN
    -- DOW (day of week) определяет номер дня недели в текущей даты.
    -- 0 - это воскресенье, а 6 - суббота.
    IF EXTRACT(DOW FROM CURRENT_DATE) = 0 THEN
        RAISE EXCEPTION 'No updates on Sunday';
    END IF;
    RETURN NULL;
END;
$$;

CREATE OR REPLACE TRIGGER update_countries_percents
    AFTER INSERT OR DELETE
    ON student.products
    FOR EACH STATEMENT
EXECUTE FUNCTION refresh_goods_by_countries();

-- создаём таблицу
CREATE TABLE price_history
(
    product_id INTEGER,
    price      DECIMAL(9, 2),
    created_at TIMESTAMP,
    PRIMARY KEY (product_id, created_at)
);

-- вносим текущие цены
INSERT INTO price_history
SELECT id, price, CURRENT_TIMESTAMP
FROM student.products;

-- создаём триггерную функцию
CREATE OR REPLACE FUNCTION save_price_history()
    RETURNS trigger
    LANGUAGE plpgsql
AS
$$
BEGIN
    -- проверяем, что цена изменилась, используя NULL SAFE сравнение
    IF OLD.price IS DISTINCT FROM NEW.price THEN
        -- сохраняем данные в таблицу
        INSERT INTO price_history (product_id, price, created_at)
        VALUES (NEW.id, NEW.price, CURRENT_TIMESTAMP);
    END IF;
    -- можем вернуть NULL, так как время события для триггера AFTER
    -- и возврат функции ни на что не влияет
    RETURN NULL;
END
$$;

-- пишем триггер, вызывающий функцию save_price_history
-- после изменения или добавления строк в таблице products
CREATE OR REPLACE TRIGGER save_price_history
    AFTER UPDATE OR INSERT
    ON student.products
    FOR EACH ROW
EXECUTE FUNCTION save_price_history();

CREATE OR REPLACE FUNCTION save_price_history()
    RETURNS trigger
    LANGUAGE plpgsql
AS
$$
BEGIN
    -- В этот раз внутри функции никаких условий не пишем.
    INSERT INTO price_history (product_id, price, created_at)
    VALUES (NEW.id, NEW.price, CURRENT_TIMESTAMP);
    RETURN NULL;
END
$$;

CREATE OR REPLACE TRIGGER save_price_history
-- убираем условие INSERT, чтобы можно было в условии использовать OLD
    AFTER UPDATE
    ON student.products
    FOR EACH ROW
-- записываем после ключевого слова WHEN логическое выражение в скобках
    WHEN (OLD.price IS DISTINCT FROM NEW.price)
EXECUTE FUNCTION save_price_history();

-- изменяем цену товара с id = 1
UPDATE student.products
SET price = price + 1
WHERE id = 1;
-- вместо 1 можно использовать id любой существующей записи

-- проверяем историю изменений
SELECT product_id, price, created_at
FROM price_history
WHERE product_id = 1;

ALTER TABLE student.products
    ADD COLUMN updated_at timestamp;

CREATE OR REPLACE FUNCTION set_product_update_timestamp()
    RETURNS trigger
    LANGUAGE plpgsql
AS
$$
BEGIN
    -- назначаем значение полю updated_at
    -- равное текущей временной метке
    NEW.updated_at = CURRENT_TIMESTAMP;

    -- возвращаем NEW
    RETURN NEW;
END
$$;

CREATE OR REPLACE TRIGGER set_product_update_timestamp
    BEFORE UPDATE
    ON student.products
    FOR EACH ROW
EXECUTE FUNCTION set_product_update_timestamp();

UPDATE student.products
SET price = price * 0.95
WHERE category = 'Модные аксессуары';

SELECT name, price, updated_at
FROM student.products
WHERE category = 'Модные аксессуары'
LIMIT 3;

CREATE TABLE changes_history
(
    id            BIGSERIAL PRIMARY KEY,
    schema        TEXT,
    changed_table TEXT,
    action        TEXT,
    changed_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    old_row_data  JSON,
    new_row_data  JSON
);

CREATE OR REPLACE FUNCTION save_changes_history()
    RETURNS trigger
    LANGUAGE plpgsql
AS
$$
BEGIN
    INSERT INTO changes_history (schema,
                                 changed_table,
                                 action,
                                 old_row_data,
                                 new_row_data)
    VALUES (TG_TABLE_SCHEMA,
            TG_TABLE_NAME,
            TG_OP,
            TO_JSON(OLD),
            TO_JSON(NEW));

    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER products_change
    AFTER UPDATE OR INSERT OR DELETE
    ON student.products
    FOR EACH ROW
EXECUTE FUNCTION save_changes_history();

-- в рамках тестирования увеличиваем количество всех товаров на 1
UPDATE student.products
SET amount = amount + 1;

SELECT *
FROM changes_history
ORDER BY id DESC
LIMIT 3;