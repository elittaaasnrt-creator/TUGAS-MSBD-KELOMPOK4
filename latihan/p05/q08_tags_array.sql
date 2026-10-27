-- Diminta: mengisi kolom tags (array) dan mencari baris berdasarkan tag tertentu.
-- Dipilih: memakai literal ARRAY[...] untuk mengisi, dan operator ANY() untuk pencarian.
-- Alternatif: menyimpan tag sebagai string dipisah koma; tidak dipilih karena kalah efisien dan tidak bisa memakai operator array bawaan Postgres.

-- Mengisi tags dengan tiga nilai
UPDATE lab5.rental_tx
SET tags = ARRAY['promo', 'akhir-pekan', 'anggota']
WHERE rental_id = 1;

-- Mencari baris yang memiliki tag promo
SELECT rental_id, tags
FROM lab5.rental_tx
WHERE 'promo' = ANY(tags);