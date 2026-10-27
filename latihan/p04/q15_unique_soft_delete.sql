-- Diminta: membuktikan UNIQUE biasa menghalangi judul yang sudah soft-delete, lalu menggantinya dengan unique index parsial.
-- Dipilih: UNIQUE biasa diuji terlebih dahulu, kemudian partial unique index dengan WHERE deleted_at IS NULL.
-- Alternatif: memakai UNIQUE(title, deleted_at); tidak dipilih karena nilai NULL dapat membuat beberapa baris soft-delete tetap lolos.

SET search_path = lab4, public;

-- Tambahkan kolom soft-delete.
ALTER TABLE lab4.film
ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

-- Pilih satu film sebagai data uji.
-- Film asli dibuat soft-delete.
UPDATE lab4.film
SET deleted_at = now()
WHERE film_id = 1;

-- UNIQUE biasa.
ALTER TABLE lab4.film
ADD CONSTRAINT film_judul_unik UNIQUE (title);

-- Coba mendaftarkan ulang judul yang sudah soft-delete.
-- Seharusnya GAGAL karena UNIQUE tetap melihat baris tersebut.
INSERT INTO lab4.film (
    film_id,
    title,
    description,
    release_year,
    language_id,
    rental_duration,
    rental_rate,
    length,
    replacement_cost,
    rating,
    last_update,
    special_features,
    fulltext,
    deleted_at
)
SELECT
    (SELECT max(film_id) + 1 FROM lab4.film),
    title,
    description,
    release_year,
    language_id,
    rental_duration,
    rental_rate,
    length,
    replacement_cost,
    rating,
    now(),
    special_features,
    fulltext,
    NULL
FROM lab4.film
WHERE film_id = 1;

-- Hapus UNIQUE biasa setelah bukti masalah dicatat.
ALTER TABLE lab4.film
DROP CONSTRAINT film_judul_unik;

-- Hanya film aktif yang harus memiliki judul unik.
CREATE UNIQUE INDEX ux_film_judul_aktif
ON lab4.film (title)
WHERE deleted_at IS NULL;

-- Sekarang pendaftaran ulang judul yang sebelumnya soft-delete diperbolehkan.
INSERT INTO lab4.film (
    film_id,
    title,
    description,
    release_year,
    language_id,
    rental_duration,
    rental_rate,
    length,
    replacement_cost,
    rating,
    last_update,
    special_features,
    fulltext,
    deleted_at
)
SELECT
    (SELECT max(film_id) + 1 FROM lab4.film),
    title,
    description,
    release_year,
    language_id,
    rental_duration,
    rental_rate,
    length,
    replacement_cost,
    rating,
    now(),
    special_features,
    fulltext,
    NULL
FROM lab4.film
WHERE film_id = 1;

-- Verifikasi.
SELECT film_id, title, deleted_at
FROM lab4.film
WHERE title = (SELECT title FROM lab4.film WHERE film_id = 1);