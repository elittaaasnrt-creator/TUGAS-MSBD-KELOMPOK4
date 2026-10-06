EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM lab6.event_log WHERE wilayah = 'Sumatera Utara' AND kota = 'Medan';

CREATE STATISTICS stat_wilayah_kota (dependencies, ndistinct) ON wilayah, kota FROM lab6.event_log;
ANALYZE lab6.event_log;

EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM lab6.event_log WHERE wilayah = 'Sumatera Utara' AND kota = 'Medan';