

-- Percobaan 1: Mengubah status menjadi EXPIRED
UPDATE lab5.rental_tx
SET status = 'EXPIRED'
WHERE rental_id = 1;

-- Menambahkan nilai EXPIRED ke enum
ALTER TYPE lab5.rental_status
ADD VALUE 'EXPIRED';

-- Percobaan 2: Mengulangi UPDATE setelah enum diperbarui
UPDATE lab5.rental_tx
SET status = 'EXPIRED'
WHERE rental_id = 1;

-- Catatan hasil:
-- Percobaan pertama seharusnya gagal karena EXPIRED belum terdaftar.
-- Setelah ALTER TYPE, percobaan kedua seharusnya berhasil.