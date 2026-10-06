-- Diminta: membuat view untuk menampilkan film dengan rental_rate <= 0.99.
-- Dipilih: view sederhana dengan WHERE tanpa check option, sesuai instruksi Q1
--          (check option baru ditambahkan di Q3 untuk membandingkan perilakunya).
-- Alternatif: langsung pakai WITH CHECK OPTION dari awal; tidak dipilih karena
--          soal meminta kita membuktikan dulu masalahnya di Q2 sebelum solusinya di Q3.

CREATE VIEW lab4.film_murah AS
SELECT film_id, title, rental_rate, rating
FROM lab4.film
WHERE rental_rate <= 0.99;