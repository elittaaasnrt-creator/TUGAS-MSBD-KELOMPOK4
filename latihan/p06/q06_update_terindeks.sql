-- Q6 ? UPDATE kolom terindeks (nilai) pada hot_longgar, bandingkan dengan Q4
UPDATE lab6.hot_longgar SET nilai = nilai + 1 WHERE id % 10 = 1;

-- statistik setelah UPDATE kolom terindeks (jalankan dari sesi baru)
SELECT relname, n_tup_upd, n_tup_hot_upd,
       round(100.0*n_tup_hot_upd/NULLIF(n_tup_upd,0),1) AS persen_hot
FROM pg_stat_user_tables WHERE schemaname='lab6' AND relname = 'hot_longgar';
