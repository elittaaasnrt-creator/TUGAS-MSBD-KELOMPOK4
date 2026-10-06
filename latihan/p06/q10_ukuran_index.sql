-- Q10: Perbandingan ukuran fisik ev_salah_idx vs ev_benar_idx
SELECT relname AS nama_index, 
       pg_size_pretty(pg_relation_size(oid)) AS ukuran
FROM pg_class
WHERE relname IN ('ev_salah_idx', 'ev_benar_idx');