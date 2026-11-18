-- Diminta: ukur waktu bf cost 6, bf cost 10, dan md5.
-- Dipilih: 10 kali crypt per cost (gen_salt saja murah, biaya ada di crypt).
-- Alternatif: satu kali ukur; tidak dipilih karena terlalu noise.
\timing on
SELECT count(crypt('x', gen_salt('bf', 6)))  AS bf6  FROM generate_series(1,10);
SELECT count(crypt('x', gen_salt('bf', 10))) AS bf10 FROM generate_series(1,10);
SELECT count(md5('x' || g))                  AS md5  FROM generate_series(1,10) g;
-- Hasil: bf6 24 ms, bf10 384 ms (16x lebih lambat per 10 hash), md5 3 ms.
-- Jawaban: lambat itu disengaja; penyerang yang menebak miliaran sandi ikut diperlambat,
-- pengguna sah hanya menunggu sekali saat login. md5 terlalu cepat, mudah di-brute-force.