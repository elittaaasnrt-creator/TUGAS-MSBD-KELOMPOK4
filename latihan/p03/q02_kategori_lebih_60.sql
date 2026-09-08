-- Diminta: nama kategori beserta jumlah filmnya, hanya kategori dengan
-- lebih dari 60 film.
-- Dipilih: GROUP BY + HAVING langsung pada hasil join, karena syaratnya
-- (jumlah > 60) memang berupa agregat per grup, jadi HAVING adalah bentuk
-- paling langsung untuk itu.
-- Alternatif: derived table di FROM yang menghitung jumlah film dulu baru
-- disaring di WHERE lapisan luar; tidak dipilih karena hasilnya identik
-- tapi menambah satu lapisan subquery yang tidak perlu untuk kasus ini.

SELECT
    c.name AS kategori,
    count(*) AS jumlah_film
FROM category c
JOIN film_category fc ON fc.category_id = c.category_id
GROUP BY c.name
HAVING count(*) > 60
ORDER BY jumlah_film DESC;
