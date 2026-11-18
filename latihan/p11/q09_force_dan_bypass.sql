-- Diminta: membandingkan baris yang dilihat skema_owner sebelum dan sesudah FORCE RLS,
--          serta membandingkan efek pemberian peran pg_read_all_data vs atribut BYPASSRLS pada app_analitik.
-- Dipilih: pengujian bertahap dengan SET ROLE dan ALTER TABLE ... FORCE ROW LEVEL SECURITY,
--          lalu mengembalikan atribut BYPASSRLS dan pg_read_all_data ke kondisi aman di akhir skrip.
-- Alternatif: membiarkan FORCE RLS mati; tidak dipilih karena celah injeksi pada akun
--             pemilik tabel akan menembus isolasi seluruh penyewa.

-- 1. skema_owner SEBELUM FORCE RLS (pemilik tabel dikecualikan -> melihat semua 30000 baris)
BEGIN;
  SET LOCAL ROLE skema_owner;
  SELECT count(*) AS owner_sebelum_force FROM lab11.pelanggan;
COMMIT;

-- Nyalakan FORCE ROW LEVEL SECURITY agar pemilik pun tunduk pada kebijakan
ALTER TABLE lab11.pelanggan FORCE ROW LEVEL SECURITY;

-- 2. skema_owner SESUDAH FORCE RLS (tanpa app.tenant -> tersaring menjadi 0 baris)
BEGIN;
  SET LOCAL ROLE skema_owner;
  SELECT count(*) AS owner_sesudah_force FROM lab11.pelanggan;
COMMIT;

-- 3. app_analitik diberi peran bawaan pg_read_all_data (TIDAK membawa BYPASSRLS -> tetap 0 baris)
GRANT pg_read_all_data TO app_analitik;
BEGIN;
  SET LOCAL ROLE app_analitik;
  SELECT count(*) AS analitik_dengan_read_all FROM lab11.pelanggan;
COMMIT;

-- 4. app_analitik diberi atribut BYPASSRLS (menembus seluruh kebijakan -> melihat 30000 baris)
ALTER ROLE app_analitik BYPASSRLS;
BEGIN;
  SET LOCAL ROLE app_analitik;
  SELECT count(*) AS analitik_dengan_bypassrls FROM lab11.pelanggan;
COMMIT;

-- Kembalikan ke kondisi aman sesuai prinsip hak minimum
ALTER ROLE app_analitik NOBYPASSRLS;
REVOKE pg_read_all_data FROM app_analitik;