-- Q16: BRIN Index pada kolom terjadi_pada
SET max_parallel_workers_per_gather = 0;

CREATE INDEX IF NOT EXISTS ev_terjadi_brin_idx ON lab6.event_log USING brin (terjadi_pada);

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, customer_id, terjadi_pada FROM lab6.event_log
WHERE terjadi_pada >= timestamptz '2024-06-01 00:00+07' 
  AND terjadi_pada < timestamptz '2024-06-08 00:00+07';
