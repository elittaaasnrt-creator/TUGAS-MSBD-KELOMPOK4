-- Diminta: menjalankan rentan.py dengan masukan nama biasa sebagai pembanding normal,
--          menyalin teks SQL yang tercetak, dan menunjukkan bagian dari masukan pengguna.
-- Dipilih: menjalankan python rentan.py "Pelanggan 12" pada kontainer lab11-web dan
--          memverifikasi jumlah baris yang dikembalikan query pembanding di basis data.
-- Alternatif: langsung menyuntikkan payload tanpa baseline; tidak dipilih karena perlu
--             pembanding perilaku normal untuk melihat perubahan struktur sintaks SQL.

-- Perintah terminal (di dalam lab11-web):
-- python rentan.py "Pelanggan 12"
--
-- Teks SQL yang tercetak:
-- SELECT id, nama, kota FROM lab11.pelanggan WHERE tenant_id = 1 AND nama ILIKE '%Pelanggan 12%'
--                                                                                ^^^^^^^^^^^^
--                                                                      Bagian dari masukan pengguna

-- Query verifikasi pembanding di PostgreSQL (hasil nyata: 111 baris pada penyewa 1):
SELECT count(*) AS baris_normal
FROM lab11.pelanggan
WHERE tenant_id = 1 AND nama ILIKE '%Pelanggan 12%';