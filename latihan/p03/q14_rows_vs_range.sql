-- Diminta: menjalankan ulang Q13 tanpa klausa frame (memakai RANGE
-- default), lalu membandingkan hasilnya dengan Q13 dan mencatat jumlah
-- tanggal yang berbeda.
-- Dipilih: query yang sama seperti Q13 tapi klausa ROWS dihilangkan,
-- dibandingkan dengan hasil Q13 memakai EXCEPT untuk mencari baris yang
-- nilainya berbeda antara kedua versi.
-- Alternatif: FULL JOIN kedua hasil lalu bandingkan kolom satu-satu;
-- tidak dipilih karena EXCEPT lebih ringkas untuk mencari selisih baris
-- tanpa perlu menulis kondisi JOIN dan perbandingan kolom manual.

WITH omzet_harian AS (
    SELECT 
        DATE(payment_date) AS tanggal,
        SUM(amount) AS total_omzet
    FROM payment
    GROUP BY DATE(payment_date)
),
q13_rows AS (
    SELECT 
        tanggal,
        total_omzet,
        SUM(total_omzet) OVER (ORDER BY tanggal ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_kumulatif,
        ROUND(AVG(total_omzet) OVER (ORDER BY tanggal ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS rerata_bergerak_7hari
    FROM omzet_harian
),
q14_range AS (
    SELECT 
        tanggal,
        total_omzet,
        SUM(total_omzet) OVER (ORDER BY tanggal) AS total_kumulatif,
        ROUND(AVG(total_omzet) OVER (ORDER BY tanggal), 2) AS rerata_bergerak_7hari
    FROM omzet_harian
),
perbedaan AS (
    SELECT 
        r13.tanggal,
        r13.total_omzet,
        r13.total_kumulatif AS kumulatif_q13,
        r14.total_kumulatif AS kumulatif_q14,
        r13.rerata_bergerak_7hari AS rerata_7hari_q13,
        r14.rerata_bergerak_7hari AS rerata_kumulatif_q14
    FROM q13_rows r13
    JOIN q14_range r14 ON r13.tanggal = r14.tanggal
    WHERE r13.rerata_bergerak_7hari <> r14.rerata_bergerak_7hari
       OR r13.total_kumulatif <> r14.total_kumulatif
)
SELECT 
    p.*,
    COUNT(*) OVER () AS jumlah_tanggal_berbeda
FROM perbedaan p
ORDER BY p.tanggal;
