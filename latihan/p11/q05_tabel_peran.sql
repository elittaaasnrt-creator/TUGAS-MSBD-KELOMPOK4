-- Diminta: tabel tujuh peran lab11, kemampuan, dan status login.
-- Dipilih: ambil fakta dari pg_roles dan pg_auth_members, bukan dari ingatan.
-- Alternatif: tabel tulis tangan; tidak dipilih karena bisa menyimpang dari kenyataan.
SELECT rolname, rolcanlogin AS bisa_login, rolsuper, rolbypassrls
FROM pg_roles WHERE rolname LIKE 'app\_%' OR rolname = 'skema_owner' ORDER BY 1;
SELECT r.rolname AS peran, m.rolname AS anggota_dari
FROM pg_auth_members a JOIN pg_roles r ON r.oid = a.member JOIN pg_roles m ON m.oid = a.roleid
WHERE r.rolname LIKE 'app\_%' ORDER BY 1;
-- Tabel tujuh peran (dari pg_roles; semua bukan superuser dan tanpa BYPASSRLS):
-- | Peran        | Login | Boleh melakukan                                                  |
-- | skema_owner  | tidak | pemilik skema dan tabel lab11: DDL dan GRANT; tidak dipakai aplikasi |
-- | app_read     | tidak | SELECT pada pelanggan (tunduk RLS); dipakai lewat keanggotaan      |
-- | app_write    | tidak | SELECT/INSERT/UPDATE/DELETE pada pelanggan (tunduk RLS)            |
-- | app_laporan  | ya    | anggota app_read; baca laporan; SELECT otomatis pada tabel baru skema_owner |
-- | app_analitik | ya    | tanpa hak awal; nanti hanya membaca tampilan tersamar              |
-- | app_portal   | ya    | anggota app_write; aplikasi portal penyewa                         |
-- | app_auditor  | ya    | tanpa hak awal; disiapkan untuk membaca jejak audit                |
-- Satu kalimat: aplikasi tidak pernah login sebagai pemilik karena hak pemilik (DROP, ALTER,
-- GRANT) tidak bisa dicabut, sehingga satu celah injection menyerahkan seluruh skema.