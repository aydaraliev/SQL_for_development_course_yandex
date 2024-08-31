CREATE INDEX user_created_at_idx ON tools_shop.users (created_at);

EXPLAIN ANALYZE
SELECT user_id
FROM tools_shop.users
WHERE created_at = '2020-01-21'
  AND email != 'ReemWeber1976@gmail.com';

EXPLAIN ANALYZE
SELECT *
FROM tools_shop.users
ORDER BY created_at
LIMIT 10 OFFSET 1000;

EXPLAIN ANALYZE
SELECT *
FROM tools_shop.users
ORDER BY user_id
LIMIT 10 OFFSET 1000;

EXPLAIN ANALYZE
SELECT *,
       row_number() OVER (ORDER BY user_id),
       count(*) OVER (PARTITION BY last_name)
FROM tools_shop.users;

EXPLAIN ANALYZE
SELECT *
FROM orders o
         JOIN coupons c ON o.order_sum > c.min_sum;

EXPLAIN ANALYZE
SELECT *
FROM orders o
         JOIN clients c ON c.id_client = o.id_client;

EXPLAIN ANALYZE
SELECT *
FROM clients;

INSERT INTO clients (first_name, last_name, city)
SELECT 'copy_' || first_name, last_name, city
FROM clients;

EXPLAIN ANALYZE
SELECT *
FROM clients;

DELETE
FROM clients
WHERE first_name like 'copy_%';

EXPLAIN ANALYZE
SELECT *
FROM clients;

ANALYZE;

EXPLAIN ANALYZE
SELECT *
FROM clients;

EXPLAIN ANALYZE
SELECT o.*
FROM clients c
         JOIN orders o ON o.id_client = c.id_client
WHERE o.id_client = 958;

CREATE INDEX ix_orders_client_id ON orders (id_client);

ANALYZE;

EXPLAIN ANALYZE
SELECT o.*
FROM clients c
         JOIN orders o ON o.id_client = c.id_client
WHERE o.id_client = 958;

CREATE INDEX ix_clients_client_id ON clients (id_client);

EXPLAIN ANALYZE
SELECT o.*
FROM clients c
         JOIN orders o ON o.id_client = c.id_client
WHERE o.id_client = 958;

EXPLAIN ANALYZE
SELECT c.id_client, c.first_name, o.id_order, o.order_sum
FROM clients c
         JOIN (SELECT * FROM orders ORDER BY id_client) o ON o.id_client = c.id_client
WHERE o.order_sum > 15000;

EXPLAIN ANALYZE
SELECT c.id_client, c.first_name, o.id_order, o.order_sum
FROM clients c
         JOIN orders o ON o.id_client = c.id_client
WHERE o.order_sum > 15000
ORDER BY o.id_client;