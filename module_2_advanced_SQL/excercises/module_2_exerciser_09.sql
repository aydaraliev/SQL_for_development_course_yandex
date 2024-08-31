/* 1. Напишите запрос к таблице tools_shop.orders, который выведет:
    дату и время оплаты заказа paid_at;
    сумму заказа total_amt;
    сумму заказа с накоплением, отсортированную по возрастанию даты и времени оплаты заказа. */

SELECT paid_at, total_amt, SUM(total_amt) OVER (ORDER BY paid_at)
FROM tools_shop.orders;

/* 2. Напишите запрос к таблице tools_shop.orders, который выведет:
    идентификатор пользователя user_id;
    дату и время оплаты заказа paid_at;
    сумму заказа total_amt;
    сумму заказа с накоплением для каждого пользователя, отсортированную по возрастанию
    даты и времени оплаты заказа. */

SELECT user_id, paid_at, total_amt, SUM(total_amt) OVER (PARTITION BY user_id ORDER BY paid_at)
FROM tools_shop.orders;

/* 3. Напишите запрос к таблице tools_shop.orders, который выведет:
    месяц оплаты заказа в формате '2016-02-01', приведённый к типу date, — первый день месяца;
    сумму заказа total_amt;
    сумму заказов по месяцам с накоплением, отсортированную по месяцу оплаты заказа. */

SELECT DATE_TRUNC('month', paid_at)::date                          AS month,
       total_amt,
       SUM(total_amt) OVER (ORDER BY DATE_TRUNC('month', paid_at)) AS cumulative_sum
FROM tools_shop.orders
ORDER BY month;

/* 4. Рассчитайте сумму трат на привлечение пользователей с накоплением по месяцам
с 2017 по 2018 год включительно. Напишите запрос к таблице tools_shop.costs, который
выведет уникальные записи из двух столбцов:
    месяц формирования заказа, приведённый к типу date — в формате '2016-02-01';
    сумму трат на текущий месяц с накоплением.
Результат отсортируйте по месяцу формирования заказа. */

SELECT DISTINCT DATE_TRUNC('month', created_at)::date,
                SUM(costs) OVER (ORDER BY DATE_TRUNC('month', created_at)::date )
FROM tools_shop.costs
WHERE DATE_TRUNC('month', created_at)::date BETWEEN '2017-01-01' AND '2018-12-31'
ORDER BY 1;