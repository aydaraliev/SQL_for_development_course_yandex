/* 1. Сопоставьте данные из таблицы с английскими названиями столбцов из описания БД.
   Затем напишите запрос, который добавит в таблицу поставщиков suppliers информацию о
   новом контрагенте:
Поле	            Значение
Наименование	    ООО «Птичка»
Адрес	            г. Москва, ул. 3-я Ямская, д. 345
Телефон	            687-44-55
Электронная почта	contact@ptichka.ru
Контактное лицо	    Голубев Антон Игоревич
Банк	            ООО «МКБ»
Счёт	            40801234567890 */

INSERT INTO suppliers (name, email, phone, address,
                       contact_person, bank_name, bank_account)
VALUES ('ООО «Птичка»', 'contact@ptichka.ru', '687-44-55',
        'г. Москва, ул. 3-я Ямская, д. 345', 'Голубев Антон Игоревич',
        'ООО «МКБ»', '40801234567890');

/* 2. Напишите один запрос, чтобы добавить в таблицу customers двух покупателей:
name	            email	             phone	        address	                        birthday
Егоров Алексей	    egorov.a@mail.ru	 +7(912)0764567	Калуга, Садовая ул. 75/101	    1994-08-09
Смирнова Светлана	sveta2000@yandex.ru	 810 34-345-88	Киров, пл. Свободы 3б, кв. 17 */

INSERT INTO customers (name, email, phone, address, birthday)
VALUES ('Егоров Алексей', 'egorov.a@mail.ru', '+7(912)0764567',
        'Калуга, Садовая ул. 75/101', '1994-08-09'),
       ('Смирнова Светлана', 'sveta2000@yandex.ru', '810 34-345-88',
        'Киров, пл. Свободы 3б, кв. 17', DEFAULT);

/* 3. На склад магазина поступили новые товары. Напишите запрос, чтобы занести их
   в базу данных. Самостоятельно исследуйте таблицы  в описании БД и определите,
   в какую таблицу нужно вставить данные.
name	            category  price	  amount	      description	                            origin_country	code
Туфли женские	    Обувь	  3200	  10	          Натуральная кожа. Производство г. Калуга	Россия	        ОЖТ098057483
Сандалии мужские	Обувь	  2800	  [по умолчанию]  Ткань. Искусственная кожа.	            Китай	        ОМС789030456
Кроссовки детские	Обувь	  1200	  20	          Серия «Маша и Медведь»	                Россия	        ОДК456787651
*/

INSERT INTO products (name, category, price, amount, description, origin_country, code)
VALUES ('Туфли женские', 'Обувь', 3200, 10, 'Натуральная кожа. Производство г. Калуга',
        'Россия', 'ОЖТ098057483'),
       ('Сандалии мужские', 'Обувь', 2800, DEFAULT, 'Ткань. Искусственная кожа.',
        'Китай', 'ОМС789030456'),
       ('Кроссовки детские', 'Обувь', 1200, 20, 'Серия «Маша и Медведь»', 'Россия', 'ОДК456787651');