-- Q4 ? HOT update: fillfactor 100 vs 80, UPDATE kolom catatan (tidak terindeks)
DROP TABLE IF EXISTS lab6.hot_penuh, lab6.hot_longgar;
CREATE TABLE lab6.hot_penuh   (id int PRIMARY KEY, nilai int NOT NULL, catatan text NOT NULL) WITH (fillfactor=100);
CREATE TABLE lab6.hot_longgar (id int PRIMARY KEY, nilai int NOT NULL, catatan text NOT NULL) WITH (fillfactor=80);
CREATE INDEX hot_penuh_nilai_idx   ON lab6.hot_penuh (nilai);
CREATE INDEX hot_longgar_nilai_idx ON lab6.hot_longgar (nilai);
INSERT INTO lab6.hot_penuh   SELECT g, g, 'awal' FROM generate_series(1,100000) g;
INSERT INTO lab6.hot_longgar SELECT g, g, 'awal' FROM generate_series(1,100000) g;
ANALYZE lab6.hot_penuh;
ANALYZE lab6.hot_longgar;

-- ukuran sebelum UPDATE
SELECT relname, pg_relation_size(oid)/8192 AS halaman, pg_size_pretty(pg_relation_size(oid)) AS ukuran_sebelum
FROM pg_class WHERE oid IN ('lab6.hot_penuh'::regclass,'lab6.hot_longgar'::regclass) ORDER BY relname;

-- UPDATE 10% baris pada kolom catatan
UPDATE lab6.hot_penuh   SET catatan = 'diubah' WHERE id % 10 = 0;
UPDATE lab6.hot_longgar SET catatan = 'diubah' WHERE id % 10 = 0;

-- Q4 ? statistik HOT (jalankan dari sesi baru setelah UPDATE)
SELECT relname, n_tup_upd, n_tup_hot_upd,
       round(100.0*n_tup_hot_upd/NULLIF(n_tup_upd,0),1) AS persen_hot
FROM pg_stat_user_tables
WHERE schemaname='lab6' AND relname IN ('hot_penuh','hot_longgar') ORDER BY relname;
