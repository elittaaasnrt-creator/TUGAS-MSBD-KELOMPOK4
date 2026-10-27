-- Q5 ? Harga fillfactor: ukuran tabel dan index setelah UPDATE
SELECT relname, pg_relation_size(oid)/8192 AS halaman, pg_size_pretty(pg_relation_size(oid)) AS ukuran_sesudah
FROM pg_class WHERE oid IN ('lab6.hot_penuh'::regclass,'lab6.hot_longgar'::regclass) ORDER BY relname;

SELECT c.relname AS tabel, pg_size_pretty(pg_indexes_size(c.oid)) AS ukuran_index_total
FROM pg_class c WHERE c.oid IN ('lab6.hot_penuh'::regclass,'lab6.hot_longgar'::regclass) ORDER BY c.relname;
