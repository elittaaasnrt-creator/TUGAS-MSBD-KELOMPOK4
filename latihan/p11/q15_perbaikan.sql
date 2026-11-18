-- Diminta: mengubah pemanggilan di rentan.py agar memakai fungsi cari_aman yang berparameter,
--          mengulangi payload yang sama, mengutip hasilnya, dan menjelaskan mengapa penyaringan
--          karakter tidak akan mencapai hasil yang sama.
-- Dipilih: menggunakan query berparameter (prepared statement / placeholder %s pada psycopg2)
--          yang memisahkan saluran perintah SQL dari nilai masukan pengguna.
-- Alternatif: menyaring atau menghapus karakter tanda kutip (sanitasi blacklist); tidak dipilih
--             karena rentan terlewati oleh variasi encoding, komentar, atau injeksi non-kutip
--             serta merusak data sah (misalnya nama mengandung apostrof seperti Ma'ruf).

-- Bukti eksekusi via rentan.py (setelah pemanggilan default diubah ke cari_aman):
-- 1. Payload injection: python rentan.py "zz' OR '1'='1' --"
--    Hasil: 0 baris (aman) -> seluruh string payload diperlakukan murni sebagai teks pencarian literal.
-- 2. Masukan normal:    python rentan.py "Pelanggan 12"
--    Hasil: 100 baris (aman) -> dibatasi klausa LIMIT 100 sesuai query berparameter.

-- Simulasi ekuivalen di PostgreSQL (PREPARE / EXECUTE memisahkan struktur perintah dan parameter):
PREPARE q_cari_aman (text) AS
  SELECT count(*) AS hasil_berparameter
  FROM lab11.pelanggan
  WHERE tenant_id = 1 AND nama ILIKE $1;

EXECUTE q_cari_aman('%zz'' OR ''1''=''1'' --%');
DEALLOCATE q_cari_aman;