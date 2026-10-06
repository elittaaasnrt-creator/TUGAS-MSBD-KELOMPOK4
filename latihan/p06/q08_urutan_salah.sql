-- Q8: Uji index dengan urutan kolom salah (terjadi_pada, customer_id)
SET max_parallel_workers_per_gather = 0;

CREATE INDEX IF NOT EXISTS ev_salah_idx ON lab6.event_log (terjadi_pada, customer_id);

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, jumlah FROM lab6.event_log
WHERE customer_id = 4211
  AND terjadi_pada >= timestamptz '2024-06-01 00:00+07'
ORDER BY terjadi_pada DESC LIMIT 20;