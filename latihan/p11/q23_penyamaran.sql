-- Diminta: tampilan tersamar untuk app_analitik; SELECT langsung ke tabel harus ditolak.
-- Dipilih: view TANPA security_invoker (jalan dengan hak pemilik view), security_barrier=true.
-- Alternatif: security_invoker=true; tidak dipilih karena analis butuh hak di tabel asli.
REVOKE pg_read_all_data FROM app_analitik;
DROP VIEW IF EXISTS lab11.v_pelanggan_samar;
CREATE VIEW lab11.v_pelanggan_samar WITH (security_barrier = true) AS
SELECT id, tenant_id,
       left(nama,1) || repeat('*', greatest(length(nama)-1, 1)) AS nama,
       'xxxxxxxxxxxx' || right(nik, 4)                           AS nik,
       regexp_replace(surel, '^[^@]+', '****')                  AS surel,
       date_trunc('year', lahir)::date                          AS lahir_tahun,
       kota, round(saldo, -5)                                   AS saldo_bulat
FROM lab11.pelanggan;
REVOKE ALL   ON lab11.pelanggan         FROM app_analitik;
GRANT SELECT ON lab11.v_pelanggan_samar TO   app_analitik;

-- Uji negatif: langsung ke tabel (harus ditolak)
SET ROLE app_analitik;
SELECT current_user AS peran;
SELECT * FROM lab11.pelanggan LIMIT 1;
-- Uji positif: lewat view
SELECT * FROM lab11.v_pelanggan_samar LIMIT 3;
RESET ROLE;
-- Jawaban: ...
-- Jawaban: view tanpa security_invoker jalan dengan hak pemilik view, jadi analis cukup punya hak di view.
-- Bukti: SELECT langsung ke tabel = "permission denied for table pelanggan"; view mengembalikan data tersamar
-- (nama, NIK, surel, lahir jadi tahun, saldo dibulatkan).