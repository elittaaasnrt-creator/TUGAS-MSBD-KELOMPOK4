-- Diminta: menunjukkan bahwa menyamarkan atau menghapus pengenal langsung (nama, nik, surel,
--          rekening) belum cukup karena kombinasi pengenal semu (kota, tanggal lahir, saldo)
--          tetap dapat mengidentifikasi ulang individu secara unik, lalu menjelaskan mitigasinya.
-- Dipilih: mengukur proporsi baris yang unik secara tunggal berdasarkan kombinasi (kota, lahir)
--          pada lab11.pelanggan serta mensimulasikan tautan (JOIN) dengan tabel referensi
--          eksternal dalam transaksi ROLLBACK agar skema asli tetap bersih.
-- Alternatif: menganggap tabel sudah anonim sepenuhnya setelah menghapus kolom nama dan nik;
--             tidak dipilih karena kombinasi tanggal lahir dan kota memiliki entropi tinggi
--             yang mudah ditautkan dengan kebocoran data atau catatan publik lain.

-- 1. Cek keunikan kombinasi pengenal semu (kota + tanggal lahir) pada 30.000 baris pelanggan:
WITH kelompok_semu AS (
  SELECT kota, lahir, count(*) AS jumlah_orang
  FROM lab11.pelanggan
  GROUP BY kota, lahir
)
SELECT count(*) AS total_kombinasi_unik_tunggal
FROM kelompok_semu
WHERE jumlah_orang = 1;

-- 2. Simulasi serangan identifikasi ulang lewat penggabungan (JOIN) dataset tersamar
--    dengan sumber eksternal yang hanya mengetahui nama, kota, dan tanggal lahir:
BEGIN;
  CREATE TEMP TABLE sumber_eksternal (
    nama_publik text,
    kota        text,
    tgl_lahir   date
  ) ON COMMIT DROP;

  -- Ambil 3 sampel catatan publik dari data pelanggan yang sudah ada
  INSERT INTO sumber_eksternal (nama_publik, kota, tgl_lahir)
  SELECT nama, kota, lahir
  FROM lab11.pelanggan
  WHERE id IN (10, 25, 50);

  -- Dataset internal yang sudah dibuang pengenal langsungnya (tanpa nama, nik, surel, rekening)
  WITH dataset_tanpa_pengenal_langsung AS (
    SELECT id, tenant_id, kota, lahir, saldo
    FROM lab11.pelanggan
  )
  SELECT e.nama_publik AS identitas_terungkap,
         d.id          AS id_internal,
         d.kota,
         d.lahir,
         d.saldo       AS saldo_sensitif_terbaca
  FROM dataset_tanpa_pengenal_langsung d
  JOIN sumber_eksternal e
    ON d.kota = e.kota AND d.lahir = e.tgl_lahir
  ORDER BY d.id;
ROLLBACK;