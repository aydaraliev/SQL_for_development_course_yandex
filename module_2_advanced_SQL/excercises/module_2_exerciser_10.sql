/* 1.Выведите все поля таблицы tools_shop.items, добавив поле с рангом записи. */

SELECT *,
       ROW_NUMBER() OVER ()
FROM tools_shop.items;

/* 2. Проранжируйте все поля в таблице tools_shop.users по дате регистрации — от меньшей к
большей. Напишите запрос, который выведет идентификатор пользователя с рангом 2021. */

WITH users AS (SELECT *,
                      ROW_NUMBER() OVER (ORDER BY created_at)
               FROM tools_shop.users)
SELECT user_id
FROM users
WHERE row_number = 2021;

/* 3. Проранжируйте записи в таблице tools_shop.orders по дате оплаты заказа — от большей
к меньшей. Напишите запрос, который выведет стоимость заказа с рангом 50. */

WITH orders AS (SELECT *,
                       ROW_NUMBER() OVER (ORDER BY paid_at DESC)
                FROM tools_shop.orders)
SELECT total_amt
FROM orders
WHERE row_number = 50;

/* 4. Используя оконную функцию, выведите список уникальных user_id пользователей,
которые совершили три заказа и более. */

WITH order_counts AS (SELECT user_id,
                             COUNT(order_id) OVER (PARTITION BY user_id) AS order_count
                      FROM tools_shop.orders)
SELECT DISTINCT user_id
FROM order_counts
WHERE order_count >= 3;
