-- Diminta: hash kata sandi dengan crypt+gen_salt('bf',8), tunjukkan dua hash berbeda.
-- Dipilih: bcrypt (salt acak per hash, lambat), karena kata sandi cukup diverifikasi, tak perlu dibalik.
-- Alternatif: md5/sha tanpa salt; tidak dipilih karena cepat dan rentan rainbow table.
SELECT crypt('rahasia123', gen_salt('bf', 8)) AS hash1,
       crypt('rahasia123', gen_salt('bf', 8)) AS hash2;
SELECT h1 = h2 AS sama
FROM (SELECT crypt('rahasia123', gen_salt('bf', 8)) h1,
             crypt('rahasia123', gen_salt('bf', 8)) h2) s;
SELECT crypt('rahasia123', h) = h AS verifikasi_benar,
       crypt('salah', h) = h      AS verifikasi_salah
FROM (SELECT crypt('rahasia123', gen_salt('bf', 8)) h) s;
-- Jawaban: salt acak membuat hash1 <> hash2 untuk kata sandi sama. Mencegah rainbow table
-- dan membongkar massal (dua akun dengan sandi sama tak terlihat sama). Hash searah, tak bisa didekripsi.