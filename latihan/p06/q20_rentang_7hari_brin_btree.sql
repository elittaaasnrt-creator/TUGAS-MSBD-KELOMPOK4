-- Diminta: uji rentang tujuh hari dengan BRIN dan B-Tree, catat pemenang serta selisih Buffers.
-- Dipilih: menjalankan query rentang yang sama dua kali -- sekali dengan hanya BRIN aktif,
--          sekali dengan hanya B-Tree aktif -- supaya optimizer tidak bisa memilih salah satu,
--          lalu Buffers dan waktu dibandingkan head-to-head.
-- Alternatif: menjalankan EXPLAIN tanpa drop/create berganti; tidak dipilih karena jika
--          kedua index hidup bersamaan, optimizer bisa memilih salah satunya saja
--          sehingga perbandingan head-to-head tidak terjamin adil.

\timing on
SET max_parallel_workers_per_gather = 0;

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id FROM lab6.event_log
WHERE terjadi_pada >= timestamptz '2024-06-01 00:00+07'
  AND terjadi_pada <  timestamptz '2024-06-08 00:00+07';

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id FROM lab6.event_log
WHERE terjadi_pada >= timestamptz '2024-06-01 00:00+07'
  AND terjadi_pada <  timestamptz '2024-06-08 00:00+07';

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id FROM lab6.event_log
WHERE terjadi_pada >= timestamptz '2024-06-01 00:00+07'
  AND terjadi_pada <  timestamptz '2024-06-08 00:00+07';

DROP INDEX lab6.ev_terjadi_brin_idx;
CREATE INDEX ev_terjadi_btree_idx ON lab6.event_log (terjadi_pada);

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id FROM lab6.event_log
WHERE terjadi_pada >= timestamptz '2024-06-01 00:00+07'
  AND terjadi_pada <  timestamptz '2024-06-08 00:00+07';

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id FROM lab6.event_log
WHERE terjadi_pada >= timestamptz '2024-06-01 00:00+07'
  AND terjadi_pada <  timestamptz '2024-06-08 00:00+07';

EXPLAIN (ANALYZE, BUFFERS)
SELECT event_id FROM lab6.event_log
WHERE terjadi_pada >= timestamptz '2024-06-01 00:00+07'
  AND terjadi_pada <  timestamptz '2024-06-08 00:00+07';

DROP INDEX lab6.ev_terjadi_btree_idx;
CREATE INDEX ev_terjadi_brin_idx ON lab6.event_log USING brin (terjadi_pada) WITH (pages_per_range=128);