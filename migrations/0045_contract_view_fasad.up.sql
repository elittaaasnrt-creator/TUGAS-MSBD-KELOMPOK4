CREATE OR REPLACE VIEW lab4.v_film_fasad AS
SELECT 
    f.film_id, f.title, f.description, f.release_year, f.language_id,
    f.original_language_id, f.rental_duration, h.harga AS rental_rate,
    f.length, f.replacement_cost, f.rating, f.last_update,
    f.special_features, f.fulltext
FROM lab4.film f
LEFT JOIN lab4.harga_film h ON f.film_id = h.film_id AND h.wilayah = 'ID';