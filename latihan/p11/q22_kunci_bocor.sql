-- Diminta: lihat pg_stat_activity dari session kedua saat enkripsi berjalan; adakah kunci/teks terang?
-- Dipilih: bandingkan kunci lewat current_setting vs kunci literal di teks query.
-- Alternatif: hanya satu varian; tidak dipilih karena tak menunjukkan perbedaan kebocoran.
SELECT pid, usename, state, left(query, 160) AS query
FROM pg_stat_activity
WHERE query ILIKE '%pgp_sym_decrypt%' AND pid <> pg_backend_pid();
-- Hasil A (kunci via current_setting): teks query hanya memuat current_setting('app.kunci_kolom'), kunci TIDAK terlihat.
-- Hasil B (kunci literal): kunci terlihat utuh di pg_stat_activity (pid 1695, user postgres).
-- (Error "syntax error at or near s" di output = salah ketik, bukan bagian percobaan.)
-- Tempat lain yang perlu diperiksa: (1) log server PostgreSQL (log_statement / log_min_duration_statement
-- mencatat teks query berisi kunci); (2) riwayat shell/psql (~/.psql_history, history CMD) dan log aplikasi/ORM.