

DROP TRIGGER IF EXISTS film_audit_harga ON lab4.film;

CREATE TRIGGER film_audit_harga
AFTER UPDATE OF rental_rate
ON lab4.film
FOR EACH ROW
WHEN (OLD.rental_rate <> NEW.rental_rate)
EXECUTE FUNCTION lab4.catat_audit_harga();


UPDATE lab4.film
SET rental_rate = NULL
WHERE film_id = 1;


UPDATE lab4.film
SET rental_rate = 2.99
WHERE film_id = 1;


SELECT *
FROM lab4.audit_harga
ORDER BY audit_id;