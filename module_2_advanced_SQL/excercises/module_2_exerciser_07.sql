/* 1. Напишите запрос, который выведет все поля таблицы tools_shop.orders, а также
два дополнительных поля:
    user_sum — суммарную стоимость заказов для каждого пользователя.
    sum_total — суммарную стоимость всех заказов.
Отсортируйте результирующую таблицу по полю user_id. */

SELECT *,
       SUM(total_amt) OVER (PARTITION BY user_id) as user_sum,
       SUM(total_amt) OVER ()                     as sum_total
FROM tools_shop.orders;

/* 2. Напишите запрос, который выведет все поля таблицы tools_shop.users и отдельным
полем — количество пользователей в этой таблице. */

SELECT *, COUNT(user_id) OVER () AS user_number
FROM tools_shop.users;

/* 3. Напишите запрос, который выведет все поля таблицы tools_shop.orders и отдельным
полем суммарную стоимость заказов за тот же месяц, к которому принадлежит каждая конкретная
строка. Датой заказа считается дата создания заказа — created_at. Отсортируйте
результирующую таблицу по дате создания заказа. */

SELECT *, SUM(total_amt) OVER (PARTITION BY DATE_TRUNC('month', created_at)) as month_total
FROM tools_shop.orders
ORDER BY created_at;