-- Q14: Covering Index & Heap Fetches
SET max_parallel_workers_per_gather = 0;

CREATE INDEX IF NOT EXISTS ev_cover_idx ON lab6.event_log (customer_id, terjadi_pada DESC, jumlah);

-- Pengujian Sebelum VACUUM
EXPLAIN (ANALYZE, BUFFERS)
SELECT customer_id, terjadi_pada, jumlah FROM lab6.event_log
WHERE customer_id = 4211
ORDER BY terjadi_pada DESC LIMIT 20;

-- Menjalankan VACUUM ANALYZE agar Visibility Map terbarui
VACUUM ANALYZE lab6.event_log;

-- Pengujian Sesudah VACUUM
EXPLAIN (ANALYZE, BUFFERS)
SELECT customer_id, terjadi_pada, jumlah FROM lab6.event_log
WHERE customer_id = 4211
ORDER BY terjadi_pada DESC LIMIT 20;
