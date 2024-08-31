/* 1. Проранжируйте записи в таблице tools_shop.order_x_item в зависимости от значения
item_id — от меньшего к большему. Записи с одинаковым item_id должны получить один ранг.
Ранги можно указать непоследовательно. */

SELECT *,
       RANK() OVER (ORDER BY item_id)
FROM tools_shop.order_x_item;

/* 2. Проранжируйте записи в таблице tools_shop.users в зависимости от значения в поле
created_at — от большего к меньшему. Записи с одинаковым значением created_at должны
получить один ранг. Ранги должны быть указаны последовательно. */

SELECT *,
       DENSE_RANK() OVER (ORDER BY created_at DESC)
FROM tools_shop.users;