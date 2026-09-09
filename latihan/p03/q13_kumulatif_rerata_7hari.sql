-- Diminta: tampilkan omzet harian beserta total kumulatif sejak hari
-- pertama dan rata-rata bergerak tujuh hari.
-- Dipilih: dua window function dengan frame ROWS eksplisit berbeda -
-- ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW untuk kumulatif,
-- dan ROWS BETWEEN 6 PRECEDING AND CURRENT ROW untuk rata-rata 7 hari.
-- Alternatif: memakai frame RANGE default (tanpa klausa ROWS); tidak
-- dipilih karena RANGE menyertakan baris dengan nilai ORDER BY yang sama
-- (peer), sehingga hasilnya bisa salah kalau ada tanggal duplikat.

WITH omzet_harian AS (
    SELECT 
        DATE(payment_date) AS tanggal,
        SUM(amount) AS total_omzet
    FROM payment
    GROUP BY DATE(payment_date)
)
SELECT 
    tanggal,
    total_omzet,
    SUM(total_omzet) OVER (
        ORDER BY tanggal 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS total_kumulatif,
    ROUND(
        AVG(total_omzet) OVER (
            ORDER BY tanggal 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ), 2
    ) AS rerata_bergerak_7hari
FROM omzet_harian
ORDER BY tanggal;

