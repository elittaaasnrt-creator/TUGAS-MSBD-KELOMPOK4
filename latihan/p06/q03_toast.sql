-- Q3 ? TOAST: strategi penyimpanan per kolom
SELECT attname, atttypid::regtype AS tipe, attstorage
FROM pg_attribute
WHERE attrelid = 'lab6.event_log'::regclass AND attnum > 0
ORDER BY attnum;

-- Q3 ? ukuran tabel TOAST
SELECT pg_size_pretty(pg_relation_size(reltoastrelid)) AS ukuran_toast
FROM pg_class WHERE oid = 'lab6.event_log'::regclass;
