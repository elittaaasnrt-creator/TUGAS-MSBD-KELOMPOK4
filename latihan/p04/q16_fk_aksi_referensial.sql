-- Diminta: menguji perilaku foreign key dengan NO ACTION, CASCADE, dan SET NULL.
-- Dipilih: tiga tabel uji terpisah agar setiap aksi referensial dapat diamati tanpa mengganggu hasil pengujian lainnya.
-- Alternatif: mengganti constraint yang sama berulang kali; tidak dipilih karena lebih mudah mengacaukan data uji.

SET search_path = lab4, public;

DROP TABLE IF EXISTS lab4.ulasan_no_action CASCADE;
DROP TABLE IF EXISTS lab4.ulasan_cascade CASCADE;
DROP TABLE IF EXISTS lab4.ulasan_set_null CASCADE;

-- =========================================================
-- 1. NO ACTION
-- =========================================================

CREATE TABLE lab4.ulasan_no_action (
    ulasan_id bigserial PRIMARY KEY,
    film_id integer NOT NULL,
    komentar text,
    CONSTRAINT fk_ulasan_no_action
        FOREIGN KEY (film_id)
        REFERENCES lab4.film (film_id)
        ON DELETE NO ACTION
);

INSERT INTO lab4.ulasan_no_action (film_id, komentar)
VALUES (2, 'Uji NO ACTION');

-- Coba hapus film induk.
-- Seharusnya GAGAL karena masih direferensikan.
DELETE FROM lab4.film
WHERE film_id = 2;


-- =========================================================
-- 2. CASCADE
-- =========================================================

CREATE TABLE lab4.ulasan_cascade (
    ulasan_id bigserial PRIMARY KEY,
    film_id integer NOT NULL,
    komentar text,
    CONSTRAINT fk_ulasan_cascade
        FOREIGN KEY (film_id)
        REFERENCES lab4.film (film_id)
        ON DELETE CASCADE
);

INSERT INTO lab4.ulasan_cascade (film_id, komentar)
VALUES (3, 'Uji CASCADE');

-- Hapus film induk.
-- Baris ulasan terkait akan ikut terhapus.
DELETE FROM lab4.film
WHERE film_id = 3;

SELECT *
FROM lab4.ulasan_cascade
WHERE film_id = 3;


-- =========================================================
-- 3. SET NULL
-- =========================================================

CREATE TABLE lab4.ulasan_set_null (
    ulasan_id bigserial PRIMARY KEY,
    film_id integer,
    komentar text,
    CONSTRAINT fk_ulasan_set_null
        FOREIGN KEY (film_id)
        REFERENCES lab4.film (film_id)
        ON DELETE SET NULL
);

INSERT INTO lab4.ulasan_set_null (film_id, komentar)
VALUES (4, 'Uji SET NULL');

-- Hapus film induk.
-- Baris ulasan tetap ada, tetapi film_id menjadi NULL.
DELETE FROM lab4.film
WHERE film_id = 4;

SELECT *
FROM lab4.ulasan_set_null
WHERE ulasan_id = 1;
