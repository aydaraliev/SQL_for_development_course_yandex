/* 1. Из таблицы tools_shop.orders выведите поля order_id, user_id, paid_at и к ним
   добавьте поле paid_at с датой предыдущего заказа для каждого пользователя. Если
   предыдущего заказа нет, выведите дату 1 января 1980 года. */

SELECT order_id,
       user_id,
       paid_at,
       LAG(paid_at, 1, '1980-01-01') OVER (PARTITION BY user_id ORDER BY paid_at) AS previous_order
FROM tools_shop.orders
ORDER BY user_id;

/* 2. Выведите поля event_id, event_time, user_id из таблицы tools_shop.events и к ним
   добавьте поле с датой и временем следующего события для каждого пользователя. Если
   события нет, оставьте значение NULL. */

SELECT event_id,
       event_time,
       user_id,
       LEAD(event_time) OVER (PARTITION BY user_id ORDER BY event_time) AS next_event
FROM tools_shop.events
ORDER BY event_time;

/* 3. Исправьте предыдущий запрос: замените дату следующего события на интервал между
   текущим и следующим событиями. Значение интервала должно быть положительным. Если
   события нет, оставьте значение NULL. */

SELECT event_id,
       event_time,
       user_id,
       LEAD(event_time) OVER (PARTITION BY user_id ORDER BY event_time) - event_time AS next_event
FROM tools_shop.events
ORDER BY event_time;