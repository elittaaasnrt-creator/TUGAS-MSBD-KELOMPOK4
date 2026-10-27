-- Diminta: uji payload @> '{"promo": true}', apakah GIN dipakai dan bagaimana ukurannya dibanding heap.
-- Dipilih: jsonb_path_ops karena query hanya memakai operator containment (@>), bukan
--          pencarian key sembarang, sehingga index lebih kecil dan lebih cepat dibanding jsonb_ops default.
-- Alternatif: GIN default (jsonb_ops); tidak dipilih karena ukurannya lebih besar tanpa
--          menambah kemampuan untuk query @> yang diminta soal.

\timing on
SET max_parallel_workers_per_gather = 0;

CREATE INDEX ev_payload_gin_idx ON lab6.event_log USING gin (payload jsonb_path_ops);

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id FROM lab6.event_log WHERE payload @> '{"promo": true}';

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id FROM lab6.event_log WHERE payload @> '{"promo": true}';

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id FROM lab6.event_log WHERE payload @> '{"promo": true}';

SELECT pg_size_pretty(pg_relation_size('lab6.ev_payload_gin_idx')) AS ukuran_gin_payload,
       pg_size_pretty(pg_relation_size('lab6.event_log')) AS ukuran_heap;