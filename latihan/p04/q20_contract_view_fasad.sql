-- 1. Hapus trigger tulis ganda agar tidak ada penulisan ganda lagi
DROP TRIGGER IF EXISTS trg_tulis_ganda_harga ON lab4.film;
DROP FUNCTION IF EXISTS lab4.fn_tulis_ganda_harga();

-- 2. Hapus kolom rental_rate lama dari tabel lab4.film
ALTER TABLE lab4.film DROP COLUMN IF EXISTS rental_rate;

-- 3. Buat View Fasad untuk menyajikan struktur seperti semula bagi aplikasi lama
CREATE OR REPLACE VIEW lab4.v_film_fasad AS
SELECT 
    f.film_id,
    f.title,
    f.description,
    f.release_year,
    f.language_id,
    f.original_language_id,
    f.rental_duration,
    h.harga AS rental_rate,
    f.length,
    f.replacement_cost,
    f.rating,
    f.last_update,
    f.special_features,
    f.fulltext
FROM lab4.film f
LEFT JOIN lab4.harga_film h ON f.film_id = h.film_id AND h.wilayah = 'ID';