-- Diminta: membuat aturan agar periode harga film pada wilayah yang sama tidak boleh tumpang tindih.
-- Dipilih: EXCLUDE USING gist dengan film_id, wilayah, dan daterange karena aturan berlaku pada kombinasi identitas dan irisan periode.
-- Alternatif: trigger yang mengecek overlap sebelum INSERT; tidak dipilih karena dapat bermasalah ketika dua transaksi berjalan bersamaan.

SET search_path = lab4, public;

CREATE EXTENSION IF NOT EXISTS btree_gist;

DROP TABLE IF EXISTS lab4.harga_film CASCADE;

CREATE TABLE lab4.harga_film (
    harga_film_id bigserial PRIMARY KEY,
    film_id integer NOT NULL
        REFERENCES lab4.film (film_id),
    wilayah text NOT NULL,
    harga numeric(5,2) NOT NULL
        CHECK (harga >= 0),
    berlaku daterange NOT NULL,
    CONSTRAINT harga_film_tidak_overlap
        EXCLUDE USING gist (
            film_id WITH =,
            wilayah WITH =,
            berlaku WITH &&
        )
);

-- INSERT pertama: diterima.
INSERT INTO lab4.harga_film
    (film_id, wilayah, harga, berlaku)
VALUES
    (5, 'ID', 10.00, daterange('2026-01-01', '2026-04-01'));

-- INSERT kedua: periode berbeda, diterima.
INSERT INTO lab4.harga_film
    (film_id, wilayah, harga, berlaku)
VALUES
    (5, 'ID', 12.00, daterange('2026-04-01', '2026-07-01'));

-- INSERT ketiga: periode overlap, seharusnya DITOLAK.
INSERT INTO lab4.harga_film
    (film_id, wilayah, harga, berlaku)
VALUES
    (5, 'ID', 15.00, daterange('2026-03-01', '2026-05-01'));

-- Wilayah berbeda: tidak konflik.
INSERT INTO lab4.harga_film
    (film_id, wilayah, harga, berlaku)
VALUES
    (5, 'MY', 15.00, daterange('2026-03-01', '2026-05-01'));

SELECT *
FROM lab4.harga_film
ORDER BY film_id, wilayah, berlaku;