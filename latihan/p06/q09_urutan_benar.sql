-- Q9: Hapus index salah, buat index benar (customer_id, terjadi_pada DESC)
SET max_parallel_workers_per_gather = 0;

DROP INDEX IF EXISTS lab6.ev_salah_idx;

CREATE INDEX IF NOT EXISTS ev_benar_idx ON lab6.event_log (customer_id, terjadi_pada DESC);

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, jumlah FROM lab6.event_log
WHERE customer_id = 4211
  AND terjadi_pada >= timestamptz '2024-06-01 00:00+07'
ORDER BY terjadi_pada DESC LIMIT 20;