-- Diminta: Membuat tabel baru lab4.harga_film dan trigger tulis ganda dari tabel lab4.film.
-- Dipilih: Menggunakan AFTER INSERT OR UPDATE trigger pada lab4.film agar perubahan harga langsung tercermin ke lab4.harga_film secara realtime.
-- Alternatif: Menggunakan sinkronisasi periodik (batch process); tidak dipilih karena ada jeda waktu (delay) yang berisiko membuat data tidak konsisten.

-- 1. Buat tabel baru lab4.harga_film
CREATE TABLE IF NOT EXISTS lab4.harga_film (
    harga_id bigserial PRIMARY KEY,
    film_id integer NOT NULL REFERENCES lab4.film(film_id),
    wilayah text NOT NULL DEFAULT 'ID',
    harga numeric(5,2) NOT NULL CHECK (harga >= 0),
    berlaku daterange NOT NULL DEFAULT daterange('2026-01-01', NULL)
);

-- 2. Buat fungsi trigger tulis ganda
CREATE OR REPLACE FUNCTION lab4.fn_tulis_ganda_harga()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO lab4.harga_film (film_id, wilayah, harga)
    VALUES (NEW.film_id, 'ID', NEW.rental_rate)
    ON CONFLICT DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Buat trigger pada tabel lab4.film
DROP TRIGGER IF EXISTS trg_tulis_ganda_harga ON lab4.film;
CREATE TRIGGER trg_tulis_ganda_harga
AFTER INSERT OR UPDATE OF rental_rate ON lab4.film
FOR EACH ROW
EXECUTE FUNCTION lab4.fn_tulis_ganda_harga();