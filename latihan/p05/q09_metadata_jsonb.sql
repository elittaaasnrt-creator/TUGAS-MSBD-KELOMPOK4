-- Diminta: menyimpan data terstruktur (channel, device) di kolom metadata JSONB dan mengambil salah satu key-nya.
-- Dipilih: memakai literal JSONB langsung dan operator ->> untuk ambil nilai sebagai teks.
-- Alternatif: memecah channel/device jadi kolom terpisah; tidak dipilih karena metadata sifatnya fleksibel dan bisa berubah struktur ke depan.

-- Menyimpan metadata berupa JSONB
UPDATE lab5.rental_tx
SET metadata = '{"channel":"web","device":"android"}'::jsonb
WHERE rental_id = 1;

-- Mengambil nilai channel dari metadata
SELECT rental_id,
       metadata ->> 'channel' AS kanal
FROM lab5.rental_tx
WHERE rental_id = 1;