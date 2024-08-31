/* 1. Напишите запрос для выборки всех поставщиков, в котором будет имя поставщика,
   его телефон и адрес электронной почты. */

SELECT name, phone, email
FROM suppliers;

/* 2. Выведите список товаров, содержащий поля name, category, description
   и price из категории «Модные аксессуары», в описании которых есть цвет «синий».
   Включите в выборку только товары, которые есть в наличии. */

SELECT name, category, description, price
FROM products
WHERE category ILIKE 'Модные аксессуары'
  AND description ILIKE '%синий%'
  AND amount > 0;

/* 3. Из таблицы products выберите товары, произведённые в Китае, цена которых не
   превышает 1000 рублей или остаток на складе не больше трёх единиц. В выборке
   должны быть наименование товара, категория, цена и количество. */

SELECT name, category, price, amount
FROM products
WHERE origin_country = 'Китай'
  AND (price <= 1000 OR amount <= 3);