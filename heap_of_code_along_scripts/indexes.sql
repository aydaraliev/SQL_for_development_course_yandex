EXPLAIN
SELECT *
FROM tools_shop.users
WHERE user_id = 98000;

CREATE UNIQUE INDEX users_user_id_idx ON tools_shop.users (user_id);

EXPLAIN
SELECT *
FROM tools_shop.users
WHERE user_id = 98000;

EXPLAIN
SELECT *
FROM tools_shop.users
WHERE first_name = 'Arata'
  and last_name = 'Hopper';

CREATE INDEX users_first_name_last_name_idx
    ON tools_shop.users (first_name, last_name);

EXPLAIN
SELECT *
FROM tools_shop.users
WHERE first_name = 'Arata'
  and last_name = 'Hopper';

EXPLAIN
SELECT *
FROM tools_shop.users
WHERE first_name = 'Arata';

EXPLAIN
SELECT *
FROM tools_shop.users
WHERE last_name = 'Hopper'

DROP INDEX tools_shop.users_first_name_last_name_idx;

CREATE INDEX users_email_idx ON tools_shop.users (email);

EXPLAIN SELECT *
FROM tools_shop.users
WHERE email = 'AAcharya@yahoo.info';

EXPLAIN 
SELECT *
FROM tools_shop.users
WHERE UPPER(email) = UPPER('Aacharya@yahoo.info');

-- сначала удалим существующий индекс
DROP INDEX tools_shop.users_email_idx;

-- создадим новый индекс для UPPER(email)
CREATE INDEX users_upper_email_idx ON tools_shop.users (UPPER(email));

EXPLAIN SELECT *
FROM tools_shop.users
WHERE UPPER(email) = UPPER('Aacharya@yahoo.info');

EXPLAIN 
SELECT *
FROM tools_shop.users
WHERE UPPER(email) LIKE UPPER('Aacharya%');

-- сначала удалим существующий индекс
DROP INDEX tools_shop.users_upper_email_idx;

-- создадим новый индекс для UPPER(email) с опцией text_pattern_ops
CREATE INDEX users_upper_email_pattern_idx
ON tools_shop.users (UPPER(email) text_pattern_ops);

EXPLAIN SELECT *
FROM tools_shop.users
WHERE UPPER(email) LIKE UPPER('AAcharya%')