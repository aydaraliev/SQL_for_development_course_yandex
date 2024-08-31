/* 1. В базе students создана таблица products с продуктами страхования и их видами.
Структура таблицы:
    CREATE TABLE products (
        id INTEGER PRIMARY KEY,
        parent_id INTEGER NULL,
        product_name VARCHAR(100) NOT NULL
    );
Таблица заполнена данными, первые строки такие:
id	parent_id	product_name
1	[null]	    Частное лицо
2	1	        Авто
3	2	        КАСКО
4	1	        Имущество
5	4	        Имущество ФЛ
6	2	        Зелёная Карта
7	1	        Здоровье
Для отчётности требуется вывести список всех продуктов категории «Имущество ФЛ».
Итоговый набор строк должен содержать столбцы id, parent_id, product_name и не
должен содержать строки с самой категорией «Имущество ФЛ», а только все её
подкатегории. Для решения воспользуйтесь поиском «в ширину». */

WITH RECURSIVE prod AS (SELECT id, parent_id, product_name
                        FROM products
                        WHERE parent_id = 4
                        UNION ALL
                        SELECT p.id, p.parent_id, p.product_name
                        FROM products p
                                 INNER JOIN prod pr
                                            ON p.parent_id = pr.id)
SELECT *
FROM prod
WHERE parent_id <> 4;

/*2. Теперь для этой же таблицы products выведите список всех продуктов категории «Авто».
Добавьте столбец level с номером уровня для наглядности. Итоговый набор строк должен
содержать столбцы id, parent_id, level, product_name, full_path и быть упорядоченным
соответственно поиску «в глубину».
Первые строки вывода запроса будут следующими:
id	    parent_id	level	product_name	            full_path
2	    1	        1	    Авто	                    Авто
6	    2	        2	    Зелёная Карта	            Авто-Зелёная Карта
1597	6	        3	    2. Зелёная карта ФЛ, 131	Авто-Зелёная Карта-2. Зелёная карта ФЛ, 131
3	    2	        2	    КАСКО	                    Авто-КАСКО */

WITH RECURSIVE prod AS (SELECT id, parent_id, 1 AS level, product_name, product_name::TEXT AS full_path
                        FROM products
                        WHERE product_name = 'Авто'
                        UNION ALL
                        SELECT p.id,
                               p.parent_id,
                               pr.level + 1,
                               p.product_name,
                               CONCAT(pr.full_path, '-', p.product_name) AS full_path
                        FROM products p
                                 INNER JOIN prod pr ON p.parent_id = pr.id)
SELECT id, parent_id, level, product_name, full_path
FROM prod
ORDER BY full_path;

/* 3. Для таблицы products выведите полный путь к продукту «2. Зелёная карта ФЛ, 131».
Запрос должен вернуть один столбец full_path с одной строкой, а путь к продукту должен
быть записан, начиная от самого наименования продукта и далее вверх до корневого узла
через дефис.
Например, для продукта «ДМС» результат запроса будет выглядеть так:
full_path
ДМС-Здоровье-Частное лицо
Задание отличается от предыдущих: здесь необходимо двигаться по иерархии вверх. */

WITH RECURSIVE product_path AS (SELECT id, parent_id, product_name, product_name::TEXT AS full_path
                                FROM products
                                WHERE product_name = '2. Зелёная карта ФЛ, 131'
                                UNION ALL
                                SELECT p.id,
                                       p.parent_id,
                                       p.product_name,
                                       CONCAT(pp.full_path, '-', p.product_name) AS full_path
                                FROM products p
                                         INNER JOIN product_path pp ON p.id = pp.parent_id)
SELECT full_path
FROM product_path
WHERE parent_id IS NULL;


