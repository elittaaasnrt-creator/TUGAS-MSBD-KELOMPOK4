-- Diminta: menunjukkan simulasi kebocoran konteks penyewa pada connection pool akibat SET tanpa LOCAL,
--          lalu membuktikan pencegahannya dengan SET LOCAL dan set_config(..., true).
-- Dipilih: mensimulasikan dua permintaan berurutan pada satu koneksi session yang sama.
-- Alternatif: memanggil RESET ALL manual di aplikasi; tidak dipilih karena rawan terlewat
--             saat terjadi exception sebelum blok pembersihan dieksekusi.

-- === SIMULASI KEBOCORAN (SALAH: SET tanpa LOCAL) ===
-- Permintaan A (Penyewa 1) menyetel konteks level-session:
SET app.tenant = '1';

-- Permintaan B (Penyewa 2) memakai ulang koneksi dari pool, tetapi lupa menyetel app.tenant:
BEGIN;
  SET LOCAL ROLE app_laporan;
  -- Bocor! Konteks penyewa 1 masih tertinggal sehingga penyewa 2 melihat 10000 baris milik penyewa 1:
  SELECT current_setting('app.tenant', true) AS konteks_tertinggal,
         count(*) AS baris_bocor_ke_penyewa2
  FROM lab11.pelanggan;
COMMIT;

-- Bersihkan sisa session sebelum uji pola aman
RESET app.tenant;

-- === POLA PENCEGAHAN (BENAR: SET LOCAL / set_config(..., true)) ===
-- Permintaan A (Penyewa 1) menggunakan set_config(..., true) di dalam transaksi:
BEGIN;
  SELECT set_config('app.tenant', '1', true);
  SET LOCAL ROLE app_laporan;
  SELECT count(*) AS akses_sah_penyewa1 FROM lab11.pelanggan; -- harapkan 10000
COMMIT; -- nilai app.tenant otomatis lenyap saat COMMIT

-- Permintaan B (Penyewa 2) mendapat koneksi bersih dari pool (meski lupa menyetel konteks, gagal aman = 0):
BEGIN;
  SET LOCAL ROLE app_laporan;
  SELECT coalesce(nullif(current_setting('app.tenant', true), ''), '<kosong>') AS konteks_setelah_commit,
         count(*) AS baris_terlihat_penyewa2 -- harapkan 0
  FROM lab11.pelanggan;
COMMIT;