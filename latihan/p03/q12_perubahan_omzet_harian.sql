-- Diminta: tampilkan omzet harian, omzet hari sebelumnya, selisih, dan
-- persentase perubahannya.
-- Dipilih: LAG(omzet) OVER (ORDER BY tanggal) untuk mengambil nilai hari
-- sebelumnya dalam baris yang sama, karena ini tepat guna untuk perbandingan
-- antarbaris berurutan tanpa self-join. NULLIF dipakai pada penyebut supaya
-- pembagian dengan nol menghasilkan NULL, bukan galat.
-- Alternatif: self-join tabel omzet harian ke dirinya sendiri dengan syarat
-- tanggal = tanggal - 1; tidak dipilih karena lebih rawan meleset saat ada
-- tanggal yang bolong (tidak ada transaksi sama sekali di hari tertentu),
-- sedangkan LAG tetap mengambil baris sebelumnya yang benar-benar ada di hasil.

WITH omzet_harian AS (
    SELECT
        date_trunc('day', p.payment_date)::date AS tanggal,
        sum(p.amount)                            AS omzet
    FROM payment p
    GROUP BY 1
)
SELECT
    tanggal,
    omzet,
    lag(omzet) OVER (ORDER BY tanggal)                        AS omzet_kemarin,
    omzet - lag(omzet) OVER (ORDER BY tanggal)                AS selisih,
    round(
        100.0 * (omzet - lag(omzet) OVER (ORDER BY tanggal))
        / NULLIF(lag(omzet) OVER (ORDER BY tanggal), 0)
    , 2)                                                       AS persen_perubahan
FROM omzet_harian
ORDER BY tanggal;