-- Diminta: menetapkan statement_timeout sebagai lapisan pembatas dampak serangan DoS/query berat,
--          mengujinya dengan query lambat, dan mencantumkan pesan galat pembatalannya.
-- Dipilih: memasang batas waktu bawaan tingkat peran (ALTER ROLE ... SET statement_timeout = '5s')
--          dan membuktikan pemutusan query lambat (pg_sleep(2)) dengan SET LOCAL statement_timeout = '200ms'.
-- Alternatif: hanya mengandalkan timeout di sisi klien/aplikasi; tidak dipilih karena klien yang
--             terputus tidak otomatis menghentikan proses query berat yang terlanjur berjalan di PostgreSQL.

-- 1. Pasang batas waktu bawaan pada peran aplikasi sebagai lapisan pertahanan keempat:
ALTER ROLE app_laporan SET statement_timeout = '5s';
ALTER ROLE app_portal  SET statement_timeout = '5s';

-- Periksa pengaturan peran yang telah terpasang:
SELECT rolname, rolconfig
FROM pg_roles
WHERE rolname IN ('app_laporan', 'app_portal')
ORDER BY rolname;

-- 2. Uji pembatalan otomatis pada query lambat (simulasi serangan DoS / heavy query):
BEGIN;
  SET LOCAL ROLE app_laporan;
  SET LOCAL statement_timeout = '200ms';
  SELECT pg_sleep(2) AS simulasi_query_berat;
COMMIT;