-- Diminta: buat tabel sebagai postgres, cek apakah app_laporan bisa membacanya, jelaskan.
-- Dipilih: has_table_privilege untuk bukti tanpa login ulang.
-- Alternatif: SET ROLE app_laporan lalu SELECT; setara, tetapi lebih panjang.
CREATE TABLE lab11.catatan_postgres (id int);
SELECT has_table_privilege('app_laporan','lab11.catatan_postgres','SELECT') AS via_postgres;
DROP TABLE lab11.catatan_postgres;
-- HASIL (postgres): via_postgres = f
-- Penjelasan: ALTER DEFAULT PRIVILEGES FOR ROLE skema_owner hanya berlaku untuk objek yang
-- DIBUAT skema_owner. Objek buatan postgres tidak tercakup. Seharusnya dijalankan:
--   ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA lab11
--     GRANT SELECT ON TABLES TO app_laporan;
-- Berlaku untuk objek baru saja, tidak retroaktif.