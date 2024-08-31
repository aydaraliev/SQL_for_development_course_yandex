EXPLAIN ANALYZE
SELECT c.id_client, c.first_name || ' ' || c.last_name AS fio, SUM(o.order_sum)
FROM clients c
         JOIN orders o ON o.id_client = c.id_client
WHERE c.city = 'Нижний Новгород'
  and o.order_sum < 6000
GROUP BY c.id_client, c.first_name || ' ' || c.last_name;