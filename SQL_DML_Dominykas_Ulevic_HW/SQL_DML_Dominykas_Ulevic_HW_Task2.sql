CREATE TABLE public.table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1, 10000000) AS x;
SELECT to_regclass('public.table_to_delete') AS table_name;
SELECT *,
    pg_size_pretty(total_bytes) AS total,
    pg_size_pretty(index_bytes) AS INDEX,
    pg_size_pretty(toast_bytes) AS toast,
    pg_size_pretty(table_bytes) AS TABLE
FROM (
        SELECT *,
            total_bytes - index_bytes - COALESCE(toast_bytes, 0) AS table_bytes
        FROM (
                SELECT c.oid,
                    nspname AS table_schema,
                    relname AS TABLE_NAME,
                    c.reltuples AS row_estimate,
                    pg_total_relation_size(c.oid) AS total_bytes,
                    pg_indexes_size(c.oid) AS index_bytes,
                    pg_total_relation_size(reltoastrelid) AS toast_bytes
                FROM pg_class c
                    LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                WHERE relkind = 'r'
            ) a
    ) a
WHERE table_name LIKE '%table_to_delete%';
DELETE FROM public.table_to_delete
WHERE REPLACE(
        col,
        'veeeeeeery_long_string',
        ''
    )::integer % 3 = 0;
-- 3.a
EXPLAIN (ANALYZE, BUFFERS, SUMMARY)
DELETE FROM public.table_to_delete
WHERE REPLACE(
        col,
        'veeeeeeery_long_string',
        ''
    )::integer % 3 = 0;
-- The execution time is 1155,273 ms that is 1,6 second
-- 3b
SELECT *,
    pg_size_pretty(total_bytes) AS total,
    pg_size_pretty(index_bytes) AS INDEX,
    pg_size_pretty(toast_bytes) AS toast,
    pg_size_pretty(table_bytes) AS TABLE
FROM (
        SELECT *,
            total_bytes - index_bytes - COALESCE(toast_bytes, 0) AS table_bytes
        FROM (
                SELECT c.oid,
                    nspname AS table_schema,
                    relname AS TABLE_NAME,
                    c.reltuples AS row_estimate,
                    pg_total_relation_size(c.oid) AS total_bytes,
                    pg_indexes_size(c.oid) AS index_bytes,
                    pg_total_relation_size(reltoastrelid) AS toast_bytes
                FROM pg_class c
                    LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                WHERE relkind = 'r'
            ) a
    ) a
WHERE table_name LIKE '%table_to_delete%';
/*
 The result of the space is the same before and after deletion
 875 MB
 
 */
--3.c
VACUUM FULL VERBOSE public.table_to_delete;
-- 3.c running same query SELECT...
-- 3.d now the total amount is 383 MB
--3.e
-- deleting
DROP TABLE IF EXISTS public.table_to_delete;
-- creating new
CREATE TABLE public.table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1, 10000000) AS x;
-- 4.a
-- this is a way to check the execution time
DO $$
DECLARE start_time TIMESTAMP;
BEGIN start_time := clock_timestamp();
TRUNCATE TABLE public.table_to_delete;
RAISE NOTICE 'TRUNCATE duration: %',
clock_timestamp() - start_time;
END $$;
-- execution took 4.106 milliseconds
--4.b
SELECT *,
    pg_size_pretty(total_bytes) AS total,
    pg_size_pretty(index_bytes) AS INDEX,
    pg_size_pretty(toast_bytes) AS toast,
    pg_size_pretty(table_bytes) AS TABLE
FROM (
        SELECT *,
            total_bytes - index_bytes - COALESCE(toast_bytes, 0) AS table_bytes
        FROM (
                SELECT c.oid,
                    nspname AS table_schema,
                    relname AS TABLE_NAME,
                    c.reltuples AS row_estimate,
                    pg_total_relation_size(c.oid) AS total_bytes,
                    pg_indexes_size(c.oid) AS index_bytes,
                    pg_total_relation_size(reltoastrelid) AS toast_bytes
                FROM pg_class c
                    LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                WHERE relkind = 'r'
            ) a
    ) a
WHERE table_name LIKE '%table_to_delete%';
/*
 
 Investigation results
 
 Initial table size:
 - Rows: 10,000,000
 - Size: approximately 575 MB
 
 After DELETE:
 - Rows remaining: approximately 6,666,667
 - Size: approximately 575 MB
 - DELETE execution time:1155,273 ms
 
 After VACUUM FULL:
 - Rows remaining: approximately 6,666,667
 - Size: 383
 
 After recreating the table:
 - Rows: 10,000,000
 - Size: approximately 575 MB
 
 After TRUNCATE:
 - Rows: 0
 - Size: 0 bytes or approximately 0 bytes
 - TRUNCATE execution time: approximately 4.106 ms
 
 Conclusions
 DELETE removes rows logically, but PostgreSQL usually keeps the physical space temporarily. The deleted rows become dead tuples. That space can later be reused by the same table, but it is not immediately returned to the operating system.
 
 VACUUM FULL rewrites the table and copies only the remaining live rows into a smaller physical file. That is why the table size decreases after VACUUM FULL.
 
 TRUNCATE removes all rows by discarding the table’s data storage more directly. It does not process ten million rows individually, so it is normally much faster than DELETE.
 
 DELETE is appropriate when only selected rows must be removed. TRUNCATE is appropriate when the entire table can be emptied and no row-by-row deletion logic is required.
 
 */