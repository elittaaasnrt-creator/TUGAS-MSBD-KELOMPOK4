-- Diminta: hitung kombinasi (kota, lahir) unik, ulangi dengan lahir jadi tahun, hitung penurunan, tunjukkan query agregat yang mengungkap satu orang.
-- Dipilih: hitung kombinasi berukuran 1 (unik) = orang yang bisa ditunjuk; plus serangan selisih dua agregat.
-- Alternatif: hanya hitung kombinasi distinct; tidak dipilih karena tak menunjukkan risiko identifikasi.
WITH a AS (SELECT kota, lahir, count(*) n FROM lab11.pelanggan GROUP BY 1,2),
     b AS (SELECT kota, date_trunc('year', lahir)::date th, count(*) n FROM lab11.pelanggan GROUP BY 1,2)
SELECT (SELECT count(*) FROM a)                 AS kombinasi_lahir,
       (SELECT count(*) FROM a WHERE n = 1)     AS unik_lahir,
       (SELECT count(*) FROM b)                 AS kombinasi_tahun,
       (SELECT count(*) FROM b WHERE n = 1)     AS unik_tahun,
       round(100.0 * ((SELECT count(*) FROM a WHERE n = 1) - (SELECT count(*) FROM b WHERE n = 1))
             / NULLIF((SELECT count(*) FROM a WHERE n = 1), 0), 1) AS turun_unik_persen;

-- Serangan selisih: dua agregat "aman" membocorkan saldo satu orang.
WITH t AS (SELECT kota, lahir FROM lab11.pelanggan GROUP BY 1,2 HAVING count(*) = 1 LIMIT 1)
SELECT t.kota, t.lahir,
       (SELECT sum(saldo) FROM lab11.pelanggan p WHERE p.kota = t.kota) AS agregat_1_kota,
       (SELECT sum(saldo) FROM lab11.pelanggan p WHERE p.kota = t.kota AND p.lahir <> t.lahir) AS agregat_2_tanpa_dia,
       (SELECT sum(saldo) FROM lab11.pelanggan p WHERE p.kota = t.kota)
     - (SELECT coalesce(sum(saldo),0) FROM lab11.pelanggan p WHERE p.kota = t.kota AND p.lahir <> t.lahir) AS saldo_satu_orang
FROM t;
-- Jawaban: ...
-- Hasil: kombinasi 18000 -> 400 (turun 97,8%); kombinasi unik 6000 -> 0 (turun 100%).
-- Jawaban: generalisasi menyatukan orang ke kelompok besar (k-anonymity), sehingga tak ada yang unik lagi.
-- Tapi selisih dua agregat (sum per kota dikurangi sum per kota tanpa dia) masih mengungkap saldo satu orang
-- (Pekanbaru, lahir 1974-11-16: 8474971.00). Agregat perlu ambang minimum kelompok.