/* 1. Рассчитайте общее количество заказов в таблице tools_shop.orders по дням их
оформления. Выведите все поля таблицы и новое поле с количеством заказов. */

SELECT *, COUNT(order_id) OVER (PARTITION BY created_at::date)
FROM tools_shop.orders;

/* 2. Рассчитайте общую выручку в таблице tools_shop.orders по месяцам оплаты заказов.
Выведите все поля таблицы и новое поле с суммой выручки. */

SELECT *, SUM(total_amt) OVER (PARTITION BY DATE_TRUNC('month', paid_at))
FROM tools_shop.orders;


