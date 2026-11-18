-- Diminta: membangun klaster tertutup dan memuat skema lab11 yang deterministik.
-- Dipilih: jaringan Docker internal: true + skrip setup lab11 buatan kelompok (berkas modul tidak ditemukan),
--          karena percobaan serangan hanya sah di lingkungan terisolasi.
-- Alternatif: PostgreSQL lokal/kampus; tidak dipilih karena melanggar aturan etika.
-- Peran: postgres. Perintah shell ada di README.md; berkas ini = verifikasi.
SELECT (SELECT count(*) FROM lab11.tenant)     AS tenant,
       (SELECT count(*) FROM lab11.pelanggan)  AS pelanggan,
       (SELECT count(*) FROM lab11.akun)       AS akun,
       (SELECT count(*) FROM lab11.transaksi)  AS transaksi;   -- harapkan 3 | 30000 | 4 | 120000
SELECT tenant_id, count(*) FROM lab11.pelanggan GROUP BY 1 ORDER BY 1;  -- tiap penyewa 10000