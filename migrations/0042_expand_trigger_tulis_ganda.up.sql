CREATE OR REPLACE FUNCTION lab4.fn_tulis_ganda_harga()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO lab4.harga_film (film_id, wilayah, harga)
    VALUES (NEW.film_id, 'ID', NEW.rental_rate)
    ON CONFLICT DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_tulis_ganda_harga ON lab4.film;
CREATE TRIGGER trg_tulis_ganda_harga
AFTER INSERT OR UPDATE OF rental_rate ON lab4.film
FOR EACH ROW
EXECUTE FUNCTION lab4.fn_tulis_ganda_harga();