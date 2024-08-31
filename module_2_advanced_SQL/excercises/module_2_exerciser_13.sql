/* 1. Напишите запрос, который проранжирует расходы на привлечение пользователей за каждый
день по убыванию. Ранги не должны повторяться.
Выгрузите три поля:
    дата, которую нужно привести к типу date;
    расходы на привлечение;
    ранг записи. */

SELECT created_at::date,
       costs,
       ROW_NUMBER() OVER (ORDER BY costs DESC) as cost_rank
FROM tools_shop.costs;

/* 2. Измените предыдущий запрос: записям с одинаковыми значениями расходов назначьте
одинаковый ранг. Ранги не должны прерываться. */

SELECT created_at::date,
       costs,
       DENSE_RANK() OVER (ORDER BY costs DESC) as cost_rank
FROM tools_shop.costs;

/* 3. Вам нужно получить количество заказов, в которых четыре и более товаров. Первая
идея — запросить данные из таблицы orders, но у вас к ней не оказалось доступа.
Пока непонятно, как решить эту проблему, а информация нужна срочно. Используйте
таблицу order_x_item и подходящую оконную функцию. */

WITH item_ranks AS (SELECT order_id,
                           ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY item_id) AS item_rank
                    FROM tools_shop.order_x_item)
SELECT COUNT(DISTINCT order_id) AS order_count
FROM item_ranks
WHERE item_rank >= 4;

/* 4. Рассчитайте количество зарегистрированных пользователей по месяцам с накоплением.
Выгрузите два поля:
    месяц регистрации, приведённый к типу date;
    общее количество зарегистрированных пользователей на текущий месяц. */

WITH monthly_registrations AS (SELECT DATE_TRUNC('month', created_at)::date AS registration_month,
                                      COUNT(user_id)                        AS monthly_count
                               FROM tools_shop.users
                               GROUP BY DATE_TRUNC('month', created_at)
                               ORDER BY registration_month),
     cumulative_registrations AS (SELECT registration_month,
                                         SUM(monthly_count) OVER (ORDER BY registration_month) AS cumulative_count
                                  FROM monthly_registrations)
SELECT registration_month,
       cumulative_count
FROM cumulative_registrations
ORDER BY registration_month;

/* 5. Админы сегодня в ударе — ваши доступы ко всем таблицам уже вернули!
Используя конструкцию WINDOW, рассчитайте суммарную стоимость заказов и количество заказов
с накоплением от месяца к месяцу.
Выгрузите поля:
    идентификатор заказа;
    месяц оплаты заказа, приведённый к типу date;
    сумма заказа;
    количество заказов с накоплением;
    суммарная стоимость заказов с накоплением. */

SELECT order_id,
       DATE_TRUNC('month', paid_at)::date AS month_,
       total_amt,
       COUNT(order_id) OVER w             AS order_count,
       SUM(total_amt) OVER w              AS order_price_sum
FROM tools_shop.orders
WINDOW w AS (ORDER BY DATE_TRUNC('month', paid_at))
ORDER BY month_, order_id;

/* 6. Напишите запрос, который выведет сумму трат на привлечение пользователей по месяцам,
а также разницу в тратах между текущим и предыдущим месяцами. Разница должна показывать,
на сколько траты текущего месяца отличаются от предыдущего. В случае, если данных по
предыдущему месяцу нет, укажите ноль.
Выгрузите поля:
    месяц, приведённый к типу date;
    траты на привлечение пользователей в текущем месяце;
    разница в тратах между текущим и предыдущим месяцами. */

WITH monthly_costs AS (SELECT DATE_TRUNC('month', created_at)::date AS month_,
                              SUM(costs)                            AS total_costs
                       FROM tools_shop.costs
                       GROUP BY DATE_TRUNC('month', created_at)::date)
SELECT month_,
       total_costs                                                        AS current_month,
       COALESCE(total_costs - LAG(total_costs) OVER (ORDER BY month_), 0) AS months_difference
FROM monthly_costs
ORDER BY month_;

/* 7. Напишите запрос, который выведет сумму выручки по годам и разницу выручки между
следующим и текущим годом. Разница должна показывать, на сколько выручка следующего года
отличается от текущего. В случае, если данных по следующему году нет, укажите ноль.
Выгрузите поля:
    год, приведённый к типу date;
    выручка за текущий год;
    разница в выручке между значением на следующей строке и значением на текущей строке. */

WITH yearly_window AS (SELECT DATE_TRUNC('year', paid_at)::date AS year_,
                              SUM(total_amt)                    AS this_year_ord
                       FROM tools_shop.orders
                       GROUP BY DATE_TRUNC('year', paid_at)::date)
SELECT year_,
       this_year_ord,
       LEAD(this_year_ord, 1, this_year_ord) OVER (ORDER BY year_) - this_year_ord AS revenue_difference
FROM yearly_window
ORDER BY year_;
