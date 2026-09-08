-- Diminta: daftar judul film dengan tarif sewa di atas rata-rata tarif
-- seluruh film, diurutkan menurun, beserta tarif, rata-rata, dan selisihnya.
-- Dipilih: subquery skalar (di WHERE dan SELECT) karena subquery cukup
-- menghasilkan satu nilai tunggal (rata-rata tarif seluruh film).
-- Alternatif: CTE terpisah untuk rata-rata; tidak dipilih karena nilainya
-- hanya dipakai sekali per baris dan query masih sederhana, jadi CTE
-- justru menambah langkah tanpa menambah kejelasan.

SELECT
    title,
    rental_rate,
    (SELECT round(avg(rental_rate), 2) FROM film) AS rata_rata,
    round(rental_rate - (SELECT avg(rental_rate) FROM film), 2) AS selisih
FROM film
WHERE rental_rate > (SELECT avg(rental_rate) FROM film)
ORDER BY rental_rate DESC;
