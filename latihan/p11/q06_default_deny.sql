-- Diminta: mengaktifkan Row-Level Security pada lab11.pelanggan dan menghitung baris
--          yang terlihat app_laporan sebelum kebijakan apa pun dibuat.
-- Dipilih: ALTER TABLE ... ENABLE ROW LEVEL SECURITY yang menerapkan perilaku default-deny,
--          diuji langsung lewat SET LOCAL ROLE app_laporan di dalam transaksi.
-- Alternatif: mengandalkan penyaring WHERE di aplikasi; tidak dipilih karena kelalaian
--             kode aplikasi berakibat kebocoran data lintas penyewa.

ALTER TABLE lab11.pelanggan ENABLE ROW LEVEL SECURITY;

BEGIN;
  SET LOCAL ROLE app_laporan;
  SELECT current_user AS peran_aktif,
         count(*)     AS sebelum_ada_kebijakan
  FROM lab11.pelanggan; -- harapkan: 0
COMMIT;