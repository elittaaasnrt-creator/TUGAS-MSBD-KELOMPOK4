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

