DROP TRIGGER IF EXISTS trg_tulis_ganda_harga ON lab4.film;
DROP FUNCTION IF EXISTS lab4.fn_tulis_ganda_harga();
ALTER TABLE lab4.film DROP COLUMN IF EXISTS rental_rate;