-- Diminta: tulis tiga query sinyal anomali (lonjakan baris per peran, akses di luar
--          jam kerja AT TIME ZONE 'Asia/Jakarta', dan ringkasan aksi), lalu tentukan
--          sinyal yang paling menangkap keluhan K2.
-- Dipilih: agregasi per menit (HAVING count(*) > 50) untuk lonjakan, filter jam < 8
--          atau >= 18 pada zona waktu Asia/Jakarta, serta ringkasan GROUP BY pelaku & aksi.
-- Alternatif: memeriksa baris audit satu per satu secara manual; tidak dipilih karena
--             tidak diskalakan pada ribuan kejadian audit.

-- 1. Lonjakan baris per peran (dalam jendela 1 menit)
SELECT pelaku, tabel, aksi,
       date_trunc('minute', waktu) AS menit,
       count(*) AS jumlah_baris
FROM lab11.jejak_audit
GROUP BY pelaku, tabel, aksi, date_trunc('minute', waktu)
HAVING count(*) > 50
ORDER BY jumlah_baris DESC;

-- 2. Akses di luar jam kerja (08:00 - 18:00 WIB)
SELECT id,
       waktu AT TIME ZONE 'Asia/Jakarta' AS waktu_wib,
       pelaku, tabel, aksi, kunci
FROM lab11.jejak_audit
WHERE EXTRACT(HOUR FROM (waktu AT TIME ZONE 'Asia/Jakarta')) < 8
   OR EXTRACT(HOUR FROM (waktu AT TIME ZONE 'Asia/Jakarta')) >= 18
ORDER BY waktu DESC;

-- 3. Ringkasan aksi per pelaku
SELECT pelaku, tabel, aksi,
       count(*) AS total_aksi,
       min(waktu AT TIME ZONE 'Asia/Jakarta') AS pertama_wib,
       max(waktu AT TIME ZONE 'Asia/Jakarta') AS terakhir_wib
FROM lab11.jejak_audit
GROUP BY pelaku, tabel, aksi
ORDER BY pelaku, tabel, aksi;

-- HASIL:
-- [Tempel keluaran ketiga kueri setelah dijalankan]
-- Penjelasan: sinyal lonjakan baris per peran dan akses di luar jam kerja paling efektif
-- menangkap anomali pencurian/perusakan massal (keluhan K2 pada Tiket #1134), karena
-- ekstraksi atau pengubahan data dalam jumlah besar umumnya dilakukan di luar jam operasional
-- normal dan menghasilkan lonjakan jumlah baris yang jauh melampaui pola transaksi harian.