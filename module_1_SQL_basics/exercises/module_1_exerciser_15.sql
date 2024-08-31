/* 1. Добавьте условие в код задания: выгрузите из таблицы invoice несколько полей, в которых указаны идентификаторы
покупателей от 20 до 50 включительно. */

SELECT customer_id,
       invoice_date,
       total
FROM invoice
WHERE customer_id >= 20
  AND customer_id <= 50;

/* 2. Добавьте к выгруженным полям информацию о месяце и неделе заказа. Информацию о дате хранит поле invoice_date.
Месяц заказа должен быть представлен первым числом месяца в формате '2009-01-01 00:00:00', а неделя
заказа — номером недели.
Измените тип данных поля invoice_date, чтобы применить функции для работы с датой. Поменяйте тип данных поля на
timestamp — тогда данные не исказятся от автоматической поправки на часовой пояс. */

SELECT customer_id,
       invoice_date,
       total,
       DATE_TRUNC('month', invoice_date::timestamp),
       EXTRACT('week' from CAST(invoice_date AS timestamp))
FROM invoice
WHERE customer_id BETWEEN 20 AND 50;

/* 3. Отфильтруйте получившуюся таблицу по номерам недель. Оставьте в таблице данные за 5, 7, 10, 33 и 48-ю недели. */

SELECT customer_id,
       invoice_date,
       total,
       DATE_TRUNC('month', CAST(invoice_date AS timestamp)),
       EXTRACT(WEEK FROM CAST(invoice_date AS timestamp)) AS week_num
FROM invoice
WHERE customer_id BETWEEN 20 AND 50
  AND EXTRACT(WEEK FROM CAST(invoice_date AS timestamp)) IN (5, 7, 10, 33, 48);

/* 4. Выгрузите из таблицы invoice всю информацию о заказах, оформленных первого числа каждого месяца, которые
были совершены клиентами без указанной компании — поле company из таблицы client не заполнено. Приведите дату к
типу timestamp. */

SELECT i.*
FROM invoice i
         JOIN client c
              USING (customer_id)
WHERE EXTRACT('day' FROM i.invoice_date::timestamp) = 1
  AND c.company IS NULL;

/* 5. Выгрузите адреса электронной почты сотрудников из города Калгари (англ. Calgary), которых наняли на работу
в 2002 году. */

SELECT email
FROM staff
WHERE EXTRACT('year' FROM CAST(hire_date as date)) = 2002
  AND city = 'Calgary';