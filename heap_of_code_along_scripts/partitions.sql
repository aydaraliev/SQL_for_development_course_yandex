SELECT document_name, document_text, document_date
FROM documents_part
WHERE document_date BETWEEN '2022-01-01' AND '2022-12-31'
LIMIT 3;

-- поиск по партиции documents_y2023
SELECT document_name, document_text, document_date
FROM documents_part
WHERE document_date BETWEEN '01.03.2023'::DATE AND '01.12.2023'::DATE
LIMIT 3;

-- поиск по партициям documents_y2022 и documents_y2023
SELECT document_name, document_text, document_date
FROM documents_part
WHERE document_date BETWEEN '01.03.2022'::DATE AND '01.12.2023'::DATE;

SELECT document_name, document_text, document_date
FROM documents_y2020
LIMIT 3;

INSERT INTO documents_part (document_name, document_text, document_date)
VALUES ('Новый документ 1', 'Говорит попугай попугаю: «Я тебя попугаю».',
        '2023-01-12');

SELECT document_name, document_text, document_date
FROM documents_y2023
WHERE document_name = 'Новый документ 1';

UPDATE documents_part
SET document_date = '2020-02-12'
WHERE document_name = 'Новый документ 1';

SELECT document_name, document_text, document_date
FROM documents_y2020
WHERE document_name = 'Новый документ 1';

SELECT document_name, document_text, document_date
FROM documents_y2023
WHERE document_name = 'Новый документ 1';

INSERT INTO documents_part (document_name, document_text, document_date)
VALUES ('Новый документ 2', 'Разраб разрабатывал, разрабатывал да не выразработал.',
        '2024-01-12');

-- удаляем партицию
DROP TABLE documents_y2013;

-- отсоединяем партицию
ALTER TABLE documents_part
    DETACH PARTITION documents_y2013;
-- удаляем отсоединённую партицию
DROP TABLE documents_y2013;

-- присоединяем партицию
ALTER TABLE documents_part
    ATTACH PARTITION documents_y2013
        FOR VALUES FROM ('2013-01-01') TO ('2014-01-01');

CREATE TABLE documents_part
(
    document_id   BIGSERIAL              NOT NULL,
    document_name CHARACTER VARYING(100) NOT NULL,
    document_text TEXT,
    document_date DATE                   NOT NULL,
    PRIMARY KEY (document_id, document_date)
) PARTITION BY RANGE (document_date);

CREATE TABLE documents_y2013m01 PARTITION OF documents_part
    FOR VALUES FROM ('2013-01-01') TO ('2013-02-01');

CREATE TABLE documents_y2013m02 PARTITION OF documents_part
    FOR VALUES FROM ('2013-02-01') TO ('2013-03-02');

CREATE TABLE documents_y2013m12 PARTITION OF documents_part
    FOR VALUES FROM ('2013-12-01') TO ('2014-02-01');

CREATE TABLE documents_y2014m01 PARTITION OF documents_part
    FOR VALUES FROM ('2014-01-01') TO ('2015-01-01');
