
ALTER TABLE lab4.film
ENABLE TRIGGER film_audit_harga;


EXPLAIN (ANALYZE, BUFFERS)
UPDATE lab4.film
SET rental_rate = rental_rate + 0.01;


ALTER TABLE lab4.film
DISABLE TRIGGER film_audit_harga;


EXPLAIN (ANALYZE, BUFFERS)
UPDATE lab4.film
SET rental_rate = rental_rate + 0.01;


ALTER TABLE lab4.film
ENABLE TRIGGER film_audit_harga;