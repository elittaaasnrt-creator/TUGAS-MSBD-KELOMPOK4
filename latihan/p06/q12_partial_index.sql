-- Q12: Partial Index vs Index Polos
SET max_parallel_workers_per_gather = 0;

CREATE INDEX IF NOT EXISTS ev_gagal_idx ON lab6.event_log (terjadi_pada DESC) WHERE status = 'GAGAL';

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, customer_id, terjadi_pada FROM lab6.event_log
WHERE status = 'GAGAL'
ORDER BY terjadi_pada DESC LIMIT 20;
