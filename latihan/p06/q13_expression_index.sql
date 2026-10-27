-- Q13: Expression Index (lower)
SET max_parallel_workers_per_gather = 0;

CREATE INDEX IF NOT EXISTS ev_email_lower_idx ON lab6.event_log (lower(email));

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id, customer_id FROM lab6.event_log
WHERE lower(email) = 'user12345@example.com';
