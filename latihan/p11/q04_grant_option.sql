-- Diminta: GRANT WITH GRANT OPTION, teruskan, cabut grant option tanpa lalu dengan CASCADE.
-- Dipilih: REVOKE GRANT OPTION FOR, agar SELECT app_write sendiri tetap utuh.
-- Alternatif: REVOKE SELECT ... CASCADE; tidak dipilih karena mencabut SELECT app_write juga.
GRANT SELECT ON lab11.transaksi TO app_write WITH GRANT OPTION;
SET ROLE app_write;
GRANT SELECT ON lab11.transaksi TO app_analitik;
RESET ROLE;
REVOKE GRANT OPTION FOR SELECT ON lab11.transaksi FROM app_write;          -- amati galatnya
-- GALAT: ERROR:  dependent privileges exist / HINT:  Use CASCADE to revoke them too.
REVOKE GRANT OPTION FOR SELECT ON lab11.transaksi FROM app_write CASCADE;
SELECT has_table_privilege('app_analitik','lab11.transaksi','SELECT') AS analitik,
       has_table_privilege('app_write','lab11.transaksi','SELECT')    AS app_write;
-- HASIL (setelah CASCADE): analitik = f, app_write = t
-- Penjelasan: hak app_analitik diturunkan lewat app_write, jadi tanpa CASCADE PostgreSQL
-- menolak agar tidak ada hak yatim. CASCADE mencabut rantai turunan saja.