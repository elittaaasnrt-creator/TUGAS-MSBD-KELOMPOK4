CREATE TABLE IF NOT EXISTS lab4.harga_film (
    harga_id bigserial PRIMARY KEY,
    film_id integer NOT NULL REFERENCES lab4.film(film_id),
    wilayah text NOT NULL DEFAULT 'ID',
    harga numeric(5,2) NOT NULL CHECK (harga >= 0),
    berlaku daterange NOT NULL DEFAULT daterange('2026-01-01', NULL)
);