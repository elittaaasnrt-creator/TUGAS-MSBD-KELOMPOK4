-- Diminta: membuat view pendapatan_kategori dengan GROUP BY, lalu mencoba
--          insert lewat view tersebut dan menjelaskan mengapa gagal.
-- Dipilih: agregasi SUM(payment.amount) per kategori film, di-join dari
--          film -> film_category -> category -> inventory -> rental -> payment.
-- Alternatif: pakai kolom rental_rate saja tanpa join ke payment; tidak dipilih
--          karena soal ini soal "pendapatan", yang secara wajar berasal dari
--          transaksi pembayaran (payment), bukan harga sewa yang tercantum di film.

CREATE VIEW lab4.pendapatan_kategori AS
SELECT c.name AS kategori,
       SUM(p.amount) AS total_pendapatan
FROM public.category c
JOIN public.film_category fc ON fc.category_id = c.category_id
JOIN public.inventory i ON i.film_id = fc.film_id
JOIN public.rental r ON r.inventory_id = i.inventory_id
JOIN public.payment p ON p.rental_id = r.rental_id
GROUP BY c.name;

INSERT INTO lab4.pendapatan_kategori (kategori, total_pendapatan)
VALUES ('Kategori Uji', 100.00);