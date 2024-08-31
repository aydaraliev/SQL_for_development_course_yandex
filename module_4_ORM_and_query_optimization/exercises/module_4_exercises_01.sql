/* 1. В приложении управления магазином отображается список поставщиков в следующем формате:
Поставщик	            Телефон
ПермьПромПоставка, ООО	6985-256-36
Простор фантазии. ОАО	356-156-63
Птичка, ООО	            687-44-55
Телескоп, ЗАО	        3323-34-72
Улыбка, ООО	            8674-34-92
…	…
Дизайн приложения такой, что одновременно на странице отображается не более десяти записей,
отсортированных по имени поставщика.
Запрос из прекода используется для формирования первой страницы. Проанализируйте запрос и
исправьте его так, чтобы минимизировать трафик между базой и приложением. */

-- Было
SELECT *
FROM query_optimization.suppliers
ORDER BY name ASC;

-- Стало
SELECT name, phone
FROM query_optimization.suppliers
ORDER BY name ASC
LIMIT 10;

/* 2. Для управления магазином менеджеры используют приложение. Каждый месяц в нём
формируется отчёт по количеству поставленных и проданных за месяц товаров. В прекоде
представлен типичный запрос, который создаёт такой отчёт. Запрос формирует отчёт за октябрь
2023 года по категории «Обувь».
Время исполнения запроса — около 5 секунд, что кажется достаточно долгим временем.
Не меняя порядок и количество соединений (JOIN), исправьте запрос так, чтобы минимизировать
вычислительную нагрузку на сервер и уменьшить время выполнения запроса. Решите задание,
не используя CTE. */

-- Было
SELECT p.name,
       total_purchases,
       total_sales
FROM query_optimization.products p
         LEFT JOIN (SELECT product_id, SUM(amount) total_sales
                    FROM query_optimization.orders o
                    WHERE to_char(created_at, 'YYYYMM') = '202310'
                    GROUP BY product_id) sales ON sales.product_id = p.id
         LEFT JOIN (SELECT product_id, SUM(amount) total_purchases
                    FROM query_optimization.supplier_orders o
                    WHERE to_char(created_at, 'YYYYMM') = '202310'
                    GROUP BY product_id) purchases ON purchases.product_id = p.id
WHERE category LIKE '%Обувь%';

-- Стало
SELECT p.name,
       total_purchases,
       total_sales
FROM query_optimization.products p
         LEFT JOIN (SELECT product_id, SUM(amount) total_sales
                    FROM query_optimization.orders o
                    WHERE created_at BETWEEN '2023-10-01' AND '2023-10-31' -- to_char(created_at, 'YYYYMM') = '202310'
                    GROUP BY product_id) sales ON sales.product_id = p.id
         LEFT JOIN (SELECT product_id, SUM(amount) total_purchases
                    FROM query_optimization.supplier_orders o
                    WHERE created_at BETWEEN '2023-10-01' AND '2023-10-31' --to_char(created_at, 'YYYYMM') = '202310'
                    GROUP BY product_id) purchases ON purchases.product_id = p.id
WHERE category = 'Обувь'
-- LIKE '%Обувь%';

/* 3.
Одним из решений предыдущего задания может быть запрос, представленный в прекоде. Запрос
работает корректно, но тимлид сказал, что по стандартам компании в таких запросах принято
использовать табличные выражения.
Перепишите запрос, используя CTE. Сохраните формат выдачи — таблица с колонками name,
total_purchases, total_sales. */

-- Было
SELECT
    p.name, total_purchases, total_sales
FROM query_optimization.products p
LEFT JOIN (
    SELECT product_id, SUM(amount) total_sales
    FROM query_optimization.orders o
    WHERE created_at BETWEEN '2023-10-01 00:00:00' AND '2023-10-31 23:59:59'
    GROUP BY product_id
) sales ON sales.product_id = p.id
LEFT JOIN (
    SELECT product_id, SUM(amount) total_purchases
    FROM query_optimization.supplier_orders o
    WHERE created_at BETWEEN '2023-10-01 00:00:00' AND '2023-10-31 23:59:59'
    GROUP BY product_id
) purchases ON purchases.product_id = p.id
WHERE category = 'Обувь';

-- Стало
WITH SalesCTE AS (
    SELECT
        product_id,
        SUM(amount) AS total_sales
    FROM
        query_optimization.orders
    WHERE
        created_at BETWEEN '2023-10-01 00:00:00' AND '2023-10-31 23:59:59'
    GROUP BY
        product_id
),
PurchasesCTE AS (
    SELECT
        product_id,
        SUM(amount) AS total_purchases
    FROM
        query_optimization.supplier_orders
    WHERE
        created_at BETWEEN '2023-10-01 00:00:00' AND '2023-10-31 23:59:59'
    GROUP BY
        product_id
)
SELECT
    p.name,
    purchases.total_purchases AS total_purchases,
    sales.total_sales AS total_sales
FROM
    query_optimization.products p
LEFT JOIN
    SalesCTE sales ON sales.product_id = p.id
LEFT JOIN
    PurchasesCTE purchases ON purchases.product_id = p.id
WHERE
    p.category = 'Обувь';

/* 4. В приложении управления магазином есть ещё один отчёт. В нём собираются данные о
поставщиках, которые не выполнили ни одной поставки в течение месяца.
В прекоде представлен типичный запрос, который создаёт такой отчёт. Запрос формирует отчёт
за ноябрь 2023 года.
Исправьте запрос так, чтобы минимизировать объём данных, считываемых сервером баз данных
с файловой системы. Сохраните порядок сортировки данных. */

-- Было
SELECT suppliers.name
FROM query_optimization.suppliers
LEFT JOIN query_optimization.supplier_orders ON
    supplier_id = suppliers.id AND
    created_at BETWEEN '2023-11-01 00:00:00' AND '2023-11-30 23:59:59'
GROUP BY suppliers.name
HAVING COUNT(supplier_orders.*) = 0
ORDER BY suppliers.name;

-- Стало
SELECT suppliers.name
FROM query_optimization.suppliers suppliers
WHERE NOT EXISTS (
    SELECT 1
    FROM query_optimization.supplier_orders so
    WHERE
        so.supplier_id = suppliers.id AND
        so.created_at BETWEEN '2023-11-01 00:00:00' AND '2023-11-30 23:59:59'
)
ORDER BY suppliers.name;
