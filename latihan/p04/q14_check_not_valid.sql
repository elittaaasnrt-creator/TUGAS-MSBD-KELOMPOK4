-- Diminta: menambahkan CHECK rental_rate tidak boleh negatif melalui NOT VALID lalu VALIDATE.
-- Dipilih: ADD CONSTRAINT ... NOT VALID agar constraint dapat dipasang tanpa langsung memeriksa data lama.
-- Alternatif: langsung ADD CONSTRAINT tanpa NOT VALID; tidak dipilih karena data lama yang melanggar akan langsung menggagalkan penambahan constraint.

SET search_path = lab4, public;

-- Masukkan data lama yang melanggar aturan.
UPDATE lab4.film
SET rental_rate = -1.00
WHERE film_id = 1;

-- Tambahkan constraint dengan NOT VALID.
ALTER TABLE lab4.film
ADD CONSTRAINT film_rental_rate_nonneg
CHECK (rental_rate >= 0) NOT VALID;

-- Tahap ini seharusnya berhasil.
SELECT film_id, title, rental_rate
FROM lab4.film
WHERE film_id = 1;

-- Validasi akan gagal karena masih ada data negatif.
ALTER TABLE lab4.film
VALIDATE CONSTRAINT film_rental_rate_nonneg;

-- Perbaiki data yang melanggar.
UPDATE lab4.film
SET rental_rate = 0.99
WHERE film_id = 1;

-- Validasi ulang. Seharusnya berhasil.
ALTER TABLE lab4.film
VALIDATE CONSTRAINT film_rental_rate_nonneg;

-- Verifikasi tidak ada data negatif.
SELECT count(*) AS data_negatif
FROM lab4.film
WHERE rental_rate < 0;