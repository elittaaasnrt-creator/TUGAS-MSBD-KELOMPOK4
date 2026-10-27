

CREATE OR REPLACE FUNCTION lab4.catat_audit_massal()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO lab4.audit_harga (
        film_id,
        harga_lama,
        harga_baru,
        diubah_oleh,
        diubah_pada
    )
    SELECT
        baru.film_id,
        lama.rental_rate,
        baru.rental_rate,
        current_user,
        now()
    FROM lama
    JOIN baru
        ON lama.film_id = baru.film_id
    WHERE lama.rental_rate IS DISTINCT FROM baru.rental_rate;

    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS film_audit_harga_massal
ON lab4.film;

CREATE TRIGGER film_audit_harga_massal
AFTER UPDATE ON lab4.film
REFERENCING OLD TABLE AS lama NEW TABLE AS baru
FOR EACH STATEMENT
EXECUTE FUNCTION lab4.catat_audit_massal();


ALTER TABLE lab4.film
DISABLE TRIGGER film_audit_harga;

EXPLAIN (ANALYZE, BUFFERS)
UPDATE lab4.film
SET rental_rate = rental_rate + 0.01;


ALTER TABLE lab4.film
ENABLE TRIGGER film_audit_harga;