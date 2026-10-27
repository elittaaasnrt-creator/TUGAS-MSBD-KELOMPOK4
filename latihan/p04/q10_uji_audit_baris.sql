
TRUNCATE TABLE lab4.audit_harga;


SELECT film_id, title, rental_rate
FROM lab4.film
WHERE film_id = 1;


UPDATE lab4.film
SET rental_rate = rental_rate + 0.01
WHERE film_id = 1;


UPDATE lab4.film
SET rental_rate = rental_rate
WHERE film_id = 1;


UPDATE lab4.film
SET title = title
WHERE film_id = 1;


SELECT *
FROM lab4.audit_harga
ORDER BY audit_id;