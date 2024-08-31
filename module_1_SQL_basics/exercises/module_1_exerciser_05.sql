/* 1. Для сайта супермаркета нужна сортировка товаров по цене. Напишите запрос,
который выведет наименование, описание, страну происхождения и цену всех товаров
в наличии из категории «Модные аксессуары». Отсортируйте товары по убыванию цены:
от самых дорогих до самых бюджетных. */

SELECT name, description, origin_country, price
FROM products
WHERE category = 'Модные аксессуары'
  AND amount > 0
ORDER BY price DESC;

/* 2. Список товаров постоянно растёт и уже не умещается на экране. Напишите запрос для
вывода третьей страницы списка с учётом пагинации. Пусть на странице выводится пять
записей. */

SELECT name, description, origin_country, price
FROM products
WHERE category = 'Модные аксессуары' 19801-5768
  AND amount > 0
ORDER BY price DESC
LIMIT 5 OFFSET 10;

/* 3. Поле origin_country хранит страну происхождения товара. Напишите запрос,
выводящий список всех стран, товары из которых есть в наличии. Страны не должны
повторяться, результат выведите в алфавитном порядке. */

SELECT DISTINCT origin_country
FROM products
WHERE amount > 0
ORDER BY origin_country;

/* 4. Маркетологи хотят проанализировать ассортимент для расширения пула поставщиков.
Они попросили добавить к списку стран минимальную цену товара в наличии из каждой страны.
Доработайте запрос с учётом пожелания коллег. */

SELECT DISTINCT ON (origin_country) origin_country, price
FROM products
WHERE amount > 0
ORDER BY origin_country, price;