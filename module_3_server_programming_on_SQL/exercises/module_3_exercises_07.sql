/* 1. Маркетологи магазина предположили, что добавление на сайт блока популярных товаров
может повысить продажи. Вам поставили задачу создать витрину из 10 самых популярных товаров.
Напишите код материализованного представления popular_products. В нём 10 строк, они
соответствуют десяти самым популярным товарам — по количеству проданных единиц за последние
три месяца. Данные для представления выбираются из таблиц orders и products.
В представлении должны быть такие поля:
    category — категория проданного товара,
    name — наименование товара,
    sold — суммарное количество проданного товара.
Данные в представлении отсортируйте по убыванию значения поля sold. */

CREATE MATERIALIZED VIEW popular_products AS
SELECT p.category,
       p.name,
       SUM(o.amount) AS sold
FROM orders o
         JOIN
     products p ON o.product_id = p.id
WHERE o.created_at >= NOW() - INTERVAL '3 months'
GROUP BY p.category,
         p.name
ORDER BY sold DESC
LIMIT 10;

/* 2. Напишите код триггерной функции с названием update_popular_products для обновления
материализованного представления  popular_products. */

CREATE OR REPLACE FUNCTION update_popular_products()
    RETURNS TRIGGER AS
$$
BEGIN
    REFRESH MATERIALIZED VIEW popular_products;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

/* 3. Напишите код триггера для вызова функции update_popular_products(), который будет
срабатывать после внесения изменений в таблицу orders. */

CREATE TRIGGER refresh_popular_products_trigger
    AFTER INSERT OR UPDATE OR DELETE
    ON orders
    FOR EACH STATEMENT
EXECUTE FUNCTION update_popular_products();
