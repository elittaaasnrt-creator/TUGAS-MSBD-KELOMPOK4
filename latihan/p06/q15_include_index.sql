-- Q15: Index INCLUDE
SET max_parallel_workers_per_gather = 0;

CREATE INDEX IF NOT EXISTS ev_include_idx ON lab6.event_log (customer_id, terjadi_pada DESC) INCLUDE (jumlah);

EXPLAIN (ANALYZE, BUFFERS)
SELECT customer_id, terjadi_pada, jumlah FROM lab6.event_log
WHERE customer_id = 4211
ORDER BY terjadi_pada DESC LIMIT 20;
