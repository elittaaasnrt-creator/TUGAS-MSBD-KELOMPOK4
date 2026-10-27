-- Diminta: uji keanggotaan tags dengan @>, bandingkan rencana dengan dan tanpa GIN.
-- Dipilih: GIN biasa pada kolom tags (text[]) karena operator @> pada array didukung
--          langsung oleh GIN tanpa opclass khusus.
-- Alternatif: tidak membuat index (seq scan); dipakai hanya sebagai pembanding lewat
--          enable_bitmapscan/enable_indexscan = off, bukan solusi permanen.

\timing on
SET max_parallel_workers_per_gather = 0;

CREATE INDEX ev_tags_gin_idx ON lab6.event_log USING gin (tags);

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id FROM lab6.event_log WHERE tags @> ARRAY['kanal:1'];

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id FROM lab6.event_log WHERE tags @> ARRAY['kanal:1'];

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id FROM lab6.event_log WHERE tags @> ARRAY['kanal:1'];

SET enable_bitmapscan = off;
SET enable_indexscan = off;
EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id FROM lab6.event_log WHERE tags @> ARRAY['kanal:1'];
RESET enable_bitmapscan;
RESET enable_indexscan;