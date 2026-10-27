-- Diminta: daftar seluruh index lab6, idx_scan, dan ukuran; tentukan index idx_scan nol
--          serta alasan jika tetap harus dipertahankan.
-- Dipilih: pg_stat_user_indexes karena menyimpan idx_scan (jumlah pemakaian index) sejak
--          statistik terakhir direset, digabung pg_relation_size untuk ukuran aktual.
-- Alternatif: pg_indexes untuk daftar definisi; tidak dipilih sendirian karena tidak
--          membawa idx_scan, jadi digabung lewat JOIN ke pg_stat_user_indexes.

\timing on

SELECT
  s.indexrelname AS nama_index,
  s.idx_scan,
  pg_size_pretty(pg_relation_size(s.indexrelid)) AS ukuran
FROM pg_stat_user_indexes s
WHERE s.schemaname = 'lab6'
ORDER BY s.idx_scan ASC, ukuran DESC;