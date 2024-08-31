/* 1. Поставщик продукта «матча» (японский зелёный чай) прислал сертификат соответствия
на товар:
{
    "product_name": "чай матча",
    "date": "23.07.2023",
    "signed": [
        "Морковкин А.А.",
        "Зеленая Е.А."
    ],
    "weight": 200,
    "country": "Вьетнам"
}
Добавьте этот сертификат в таблицу conformity_certs. */

INSERT INTO conformity_certs(product_id, cert)
SELECT id,
       '{
         "product_name": "чай матча",
         "date": "23.07.2023",
         "signed": [
           "Морковкин А.А.",
           "Зеленая Е.А."
         ],
         "weight": 200,
         "country": "Вьетнам"
       }'::jsonb
FROM products p
WHERE p.name = 'матча';

/* 2. У сертификата качества на сельдерей такая структура:
{
    "product_name": "сельдерей",
    "certifications": [
        {
            "date": "01.06.2023",
            "number": 123,
            "result": "very good"
        },
        {
            "date": "01.07.2023",
            "number": 456,
            "result": "good"
        },
        {
            "date": "01.08.2023",
            "number": 789,
            "result": "very good"
        }
    ]
}
При этом точное количество объектов в массиве certifications неизвестно. Найдите сертификат
качества на продукт «сельдерей» и выведите результат его последней сертификации
(значение по ключу result) в формате text. */

SELECT cert -> 'certifications' -> -1 ->> 'result'
FROM conformity_certs c
WHERE c.cert @> '{"product_name": "сельдерей"}';

/* 3. Это образец сертификата качества на миндальное молоко:
{
    "cert_date": "01.09.2023",
    "cert_number": 12345,
    "product_name": "миндальное молоко",
    "signed": [
        "Иванов И.И.",
        "Петров П.П."
    ]
}
Найдите фактический сертификат в таблице conformity_certs и посчитайте, сколько
человек его подписали — signed. */

SELECT JSONB_ARRAY_LENGTH(cert -> 'signed')
FROM conformity_certs cc
WHERE cc.cert @> '{"product_name": "миндальное молоко"}';

/* 4. Кажется, в сертификат на миндальное молоко закралась ошибка. Его номер — не 12345,
а 123456. Замените значение в таблице conformity_certs. */

UPDATE conformity_certs cc
SET cert = JSONB_SET(cert, '{cert_number}', '123456'::jsonb)
WHERE cc.cert @> '{"product_name": "миндальное молоко"}';

/* 5. Вот сертификат качества на сельдерей:
{
    "product_name": "сельдерей",
    "certifications": [
        {
            "date": "01.06.2023",
            "number": 123,
            "result": "very good"
        },
        {
            "date": "01.07.2023",
            "number": 456,
            "result": "good"
        },
        {
            "date": "01.08.2023",
            "number": 789,
            "result": "very good"
        }
    ]
}
Обновите значение в таблице conformity_certs. Для этого измените номер первой сертификации
в массиве certifications. Правильное значение номера — 101. */

UPDATE conformity_certs
SET cert = JSONB_SET(cert, '{certifications, 0, number}', '101'::jsonb)
WHERE cert @> '{"product_name": "сельдерей"}'

/* 6. По сертификату на сельдерей пришло дополнение. Нужно добавить к нему следующую
пару ключ-значение:
"country": "Россия"
Обновите значение в таблице conformity_certs. */

UPDATE conformity_certs
SET cert = jsonb_set(cert, '{country}', '"Россия"'::jsonb)
WHERE cert @> '{"product_name": "сельдерей"}';

/* 7. По новым стандартам фамилии подписантов больше не указываются в сертификате
качества. Исправьте сертификат на миндальное молоко и уберите из него ключ signed
и его значение. */

UPDATE conformity_certs
SET cert = cert - 'signed'
WHERE cert ? 'signed';

