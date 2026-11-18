-- Diminta: sebagai app_portal penyewa 1, ubah satu baris dan hapus satu baris uji
--          tanpa transaksi, tampilkan isi jejak_audit, lalu buktikan app_portal
--          tidak bisa membaca atau memalsukan jejak_audit.
-- Dipilih: UPDATE id = 3 (berakhiran 3, tidak punya transaksi) dan sisip-lalu-hapus
--          baris uji id = 99999 pada tenant_id = 1, kemudian uji negatif SELECT/INSERT/DELETE.
-- Alternatif: menghapus baris pelanggan existing bertransaksi; tidak dipilih karena
--             melanggar foreign key transaksi dan merusak data sebelum Q29.

-- Jalankan bagian 1 ini dengan koneksi -U app_portal:
BEGIN;
SET LOCAL app.tenant = '1';
UPDATE lab11.pelanggan SET kota = 'Binjai' WHERE id = 3;
INSERT INTO lab11.pelanggan (id, tenant_id, nama, nik, surel, lahir, kota, saldo, rekening, dibuat_pada)
VALUES (99999, 1, 'Uji Audit', '1271000000099999', 'uji@contoh.test', '2000-01-01', 'Medan', 100000, '0000099999', now());
DELETE FROM lab11.pelanggan WHERE id = 99999;
COMMIT;

-- Uji negatif masih sebagai app_portal (harus ditolak):
SELECT * FROM lab11.jejak_audit;
INSERT INTO lab11.jejak_audit (pelaku, tabel, aksi, kunci) VALUES ('palsu', 'pelanggan', 'DELETE', '3');
DELETE FROM lab11.jejak_audit;

-- Jalankan bagian 2 ini dengan koneksi -U postgres atau -U app_auditor:
SELECT id, waktu, pelaku, tabel, aksi, kunci,
       nilai_lama->>'kota' AS kota_lama,
       nilai_baru->>'kota' AS kota_baru
FROM lab11.jejak_audit
ORDER BY id DESC LIMIT 5;

-- HASIL UJI NEGATIF (app_portal):
-- ERROR:  permission denied for table jejak_audit
-- HASIL JEJAK AUDIT (postgres / app_auditor):
-- [Tempel keluaran SELECT jejak_audit setelah dijalankan]
-- Penjelasan: setiap operasi UPDATE, INSERT, dan DELETE oleh app_portal otomatis terekam
-- dengan pelaku = 'app_portal', sementara percobaan app_portal untuk mengintip atau
-- memanipulasi tabel jejak_audit langsung ditolak oleh sistem hak akses PostgreSQL.