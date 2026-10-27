-- Diminta: membuat ulang view film_murah dengan WITH CASCADED CHECK OPTION,
--          lalu mengulangi insert Q2 untuk melihat perbedaan perilakunya.
-- Dipilih: CREATE OR REPLACE VIEW dengan WITH CASCADED CHECK OPTION agar PostgreSQL
--          menolak insert/update yang melanggar syarat WHERE pada view.
-- Alternatif: WITH LOCAL CHECK OPTION; tidak dipilih karena view ini tidak bertingkat
--          (tidak dibangun di atas view lain), jadi CASCADED dan LOCAL akan berperilaku
--          sama di sini, tapi CASCADED lebih eksplisit untuk keamanan jangka panjang.

CREATE OR REPLACE VIEW lab4.film_murah AS
SELECT film_id, title, rental_rate, rating
FROM lab4.film
WHERE rental_rate <= 0.99
WITH CASCADED CHECK OPTION;

INSERT INTO lab4.film_murah (film_id, title, rental_rate, rating)
VALUES (9998, 'Judul Uji Q3', 4.99, 'PG');