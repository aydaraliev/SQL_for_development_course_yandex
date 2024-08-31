/* 1. Группировка поможет сравнить данные, но сначала их нужно отфильтровать. Напишите запрос,
который выгрузит общую выручку (поле total) в США (англ. USA). Информацию о стране хранит поле billing_country. */

SELECT sum(i.total)
FROM invoice i
WHERE billing_country = 'USA';

/* 2. Теперь можно проверить, как различаются данные по городам. Посчитайте общую выручку, количество заказов
и среднюю выручку для каждого города США. Нужное поле — billing_city. */

SELECT billing_city,
       sum(total),
       count(invoice_id),
       avg(total)
FROM invoice
WHERE billing_country = 'USA'
GROUP BY billing_city;

/* 3. Создайте новое поле cost_category на основании таблицы invoice с категориями:
    * заказы на сумму меньше одного доллара получат категорию 'low cost',
    * заказы на сумму от одного доллара и выше получат категорию 'high cost'.
Для каждой категории посчитайте сумму значений в поле total.
Результат нужно вывести только для тех заказов, которые относятся к клиентам (таблица client)
с указанным телефоном (поле phone не содержит NULL). В итоговую таблицу должны войти только два поля. */

SELECT CASE
           WHEN i.total < 1 THEN 'low cost'
           WHEN i.total >= 1 THEN 'high cost'
           END    AS cost_category,
       sum(total) AS sum_total
FROM invoice i
         JOIN client c
              USING (customer_id)
WHERE c.phone IS NOT NULL
GROUP BY cost_category
ORDER BY sum_total;

/* 4. Выведите таблицу из двух столбцов:
        * в столбце name отобразите список названий категорий (столбец name таблицы category);
        * в столбце actor_count покажите количество киноактёров, которые снимались в соответствующей категории.
Отсортируйте категории фильмов от тех, где снималось наибольшее количество актёров, к категориям с наименьшим
количеством актёров. Если в нескольких категориях снялось одинаковое количество актёров, то дополнительно
отсортируйте выборку по названию категории.
Учтите, что один и тот же актёр мог сниматься в нескольких фильмах одной категории. Нужно посчитать количество
уникальных актёров. */

SELECT c.name,
       count(DISTINCT actor_id) AS actor_count
FROM category c
         JOIN film_category fc
              USING (category_id)
         JOIN film_actor fa
              USING (film_id)
GROUP BY c.name
ORDER BY actor_count DESC, name;