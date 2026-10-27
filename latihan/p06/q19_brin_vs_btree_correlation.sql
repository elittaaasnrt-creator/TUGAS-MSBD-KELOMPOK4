-- Diminta: periksa correlation terjadi_pada di pg_stats, bandingkan ukuran BRIN dengan B-Tree pada kolom sama.
-- Dipilih: BRIN pages_per_range=128 (default soal) karena kolom terjadi_pada diisi berurutan
--          waktu saat INSERT, sehingga correlation tinggi -- kondisi ideal untuk BRIN.
-- Alternatif: B-Tree biasa; ukurannya jauh lebih besar untuk kolom dengan correlation
--          tinggi seperti ini, dibuat di sini hanya sebagai pembanding ukuran.

\timing on
SET max_parallel_workers_per_gather = 0;

CREATE INDEX ev_terjadi_brin_idx ON lab6.event_log USING brin (terjadi_pada) WITH (pages_per_range=128);

SELECT attname, correlation
FROM pg_stats
WHERE schemaname = 'lab6' AND tablename = 'event_log' AND attname = 'terjadi_pada';

CREATE INDEX ev_terjadi_btree_idx ON lab6.event_log (terjadi_pada);

SELECT pg_size_pretty(pg_relation_size('lab6.ev_terjadi_brin_idx')) AS ukuran_brin,
       pg_size_pretty(pg_relation_size('lab6.ev_terjadi_btree_idx')) AS ukuran_btree;

DROP INDEX lab6.ev_terjadi_btree_idx;