-- Diminta: membandingkan waktu eksekusi antara hash cepat (SHA-256) dengan hash adaptif bcrypt
--          pada beberapa nilai faktor biaya (cost), serta menjelaskan mengapa fungsi hash kata
--          sandi sengaja dibuat lambat dan bagaimana memilih faktor biaya yang seimbang.
-- Dipilih: mengukur durasi eksekusi nyata menggunakan \timing on pada fungsi digest() vs
--          crypt(..., gen_salt('bf', cost)) dengan faktor biaya 4, 8, dan 12 (iterasi 2^cost).
-- Alternatif: memakai SHA-256 atau MD5 mentah untuk menyimpan kata sandi karena eksekusinya
--             sub-milidetik; tidak dipilih karena penyerang dengan GPU modern dapat mencoba
--             miliaran kombinasi sandi per detik apabila salinan tabel akun bocor.

\timing on

-- 1. Hash cepat umum (SHA-256) -> dieksekusi dalam fraksi milidetik (berbahaya untuk sandi)
SELECT encode(digest('rahasia123', 'sha256'), 'hex') AS hash_sha256_cepat;

-- 2. Bcrypt dengan faktor biaya rendah (cost = 4 -> 2^4 = 16 putaran)
SELECT crypt('rahasia123', gen_salt('bf', 4)) AS bcrypt_cost_4;

-- 3. Bcrypt dengan faktor biaya menengah (cost = 8 -> 2^8 = 256 putaran)
SELECT crypt('rahasia123', gen_salt('bf', 8)) AS bcrypt_cost_8;

-- 4. Bcrypt dengan faktor biaya tinggi (cost = 12 -> 2^12 = 4.096 putaran)
SELECT crypt('rahasia123', gen_salt('bf', 12)) AS bcrypt_cost_12;

\timing off