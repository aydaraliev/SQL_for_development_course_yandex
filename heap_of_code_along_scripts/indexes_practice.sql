SELECT pg_stat_statements_reset();
SELECT pg_stat_reset();

SELECT *
FROM documents
WHERE doc_number > 500;
SELECT *
FROM documents
WHERE doc_date > to_timestamp('26.09.2023 00:00:00',
                              'dd.mm.yyyy hh24:mi:ss');
SELECT *
FROM partners
WHERE partner_name LIKE 'mbg13%';
SELECT *
FROM partners
WHERE id = 1001;

SELECT ROUND(mean_exec_time::numeric, 2), query
FROM pg_stat_statements
ORDER BY mean_exec_time DESC;

SELECT *
FROM pg_stat_user_indexes;

CREATE INDEX partners_partner_name_pattern_idx
    ON partners (partner_name text_pattern_ops);

SELECT *
FROM partners
WHERE partner_name LIKE 'mbg13%';

SELECT *
FROM pg_stat_user_indexes;

SELECT pg_stat_statements_reset();
SELECT pg_stat_reset();

SELECT *
FROM documents
WHERE doc_number > 500;
SELECT *
FROM documents
WHERE doc_date > to_timestamp('26.09.2023 00:00:00', 'dd.mm.yyyy hh24:mi:ss');
SELECT *
FROM partners
WHERE partner_name LIKE 'mbg13%';
SELECT *
FROM partners
WHERE id = 1001;

SELECT ROUND(mean_exec_time::numeric, 2), query
FROM pg_stat_statements
ORDER BY mean_exec_time DESC;

SELECT schemaname,
       relname,
       seq_scan,
       seq_tup_read,
       idx_scan,
       idx_tup_fetch
FROM pg_stat_user_tables;

CREATE INDEX documents_doc_number_idx
    ON documents (doc_number);

SELECT pg_stat_statements_reset();
SELECT pg_stat_reset();

SELECT *
FROM documents
WHERE doc_number > 500;
SELECT *
FROM documents
WHERE doc_date > to_timestamp('26.09.2023 00:00:00',
                              'dd.mm.yyyy hh24:mi:ss');
SELECT *
FROM partners
WHERE partner_name LIKE 'mbg13%';
SELECT *
FROM partners
WHERE id = 1001;

SELECT schemaname,
       relname,
       seq_scan,
       seq_tup_read,
       idx_scan,
       idx_tup_fetch
FROM pg_stat_user_tables;

SELECT ROUND(mean_exec_time::numeric, 2), query
FROM pg_stat_statements
ORDER BY mean_exec_time DESC;