-- Diminta: mengulangi payload injection yang sama lewat koneksi app_laporan (anggota app_read
--          yang tunduk kebijakan penyewa), mencatat perubahan jumlah baris, dan mengaitkannya
--          dengan prinsip hak minimum per tabel.
-- Dipilih: menguji payload OR '1'='1' serta payload UNION SELECT ke lab11.akun menggunakan
--          peran app_laporan dengan konteks penyewa 1.
-- Alternatif: mengandalkan pembatasan peran dan RLS saja tanpa memperbaiki query; tidak dipilih
--             karena RLS tidak mencegah penyuntikan sintaks SQL pada data milik penyewa yang sama.

-- 1. Uji payload OR '1'='1' sebagai app_laporan (penyewa 1):
--    Perubahan: jumlah baris turun dari 30.000 menjadi 10.000 karena RLS menyaring data penyewa 2 & 3.
--    Yang tetap: SQL injection tetap berhasil mengembalikan seluruh 10.000 baris milik penyewa 1.
BEGIN;
  SET LOCAL ROLE app_laporan;
  SET LOCAL app.tenant = '1';
  SELECT count(*) AS baris_via_app_laporan
  FROM lab11.pelanggan
  WHERE tenant_id = 1 AND nama ILIKE '%zz' OR '1'='1'; --%';
COMMIT;

-- 2. Uji serangan lintas tabel (UNION SELECT ke lab11.akun) sebagai app_laporan:
--    Sesuai prinsip hak minimum per tabel, app_read hanya diberi hak SELECT pada lab11.pelanggan,
--    sehingga percobaan membaca lab11.akun langsung ditolak (permission denied for table akun).
BEGIN;
  SET LOCAL ROLE app_laporan;
  SET LOCAL app.tenant = '1';
  SELECT id, nama, kota FROM lab11.pelanggan WHERE tenant_id = 1 AND nama ILIKE '%zz'
  UNION SELECT id, username, kata_sandi FROM lab11.akun; --%';
COMMIT;