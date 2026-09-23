

-- Mengisi tags dengan tiga nilai
UPDATE lab5.rental_tx
SET tags = ARRAY['promo', 'akhir-pekan', 'anggota']
WHERE rental_id = 1;

-- Mencari baris yang memiliki tag promo
SELECT rental_id, tags
FROM lab5.rental_tx
WHERE 'promo' = ANY(tags);