-- Diminta: membuktikan apa yang terjadi saat insert lewat view film_murah
--          dengan rental_rate di luar syarat view (4.99, padahal view hanya <= 0.99).
-- Dipilih: INSERT langsung ke view, lalu bandingkan jumlah baris judul yang sama
--          antara view dan tabel dasar untuk melihat selisihnya.
-- Alternatif: insert langsung ke tabel lab4.film; tidak dipilih karena soal
--          secara spesifik meminta insert lewat VIEW untuk menunjukkan perilaku unik ini.

INSERT INTO lab4.film_murah (film_id, title, rental_rate, rating)
VALUES (9999, 'Judul Uji Q2', 4.99, 'PG');

SELECT count(*) AS di_view
FROM lab4.film_murah
WHERE title = 'Judul Uji Q2';

SELECT count(*) AS di_tabel_dasar
FROM lab4.film
WHERE title = 'Judul Uji Q2';