CREATE INDEX idx_event_status ON lab6.event_log(status);

EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM lab6.event_log WHERE status = 'SUKSES';

EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM lab6.event_log WHERE status = 'GAGAL';