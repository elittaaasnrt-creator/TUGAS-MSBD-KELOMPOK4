-- Diminta: membuat view penyamaran (data masking) untuk kolom sensitif (nik, surel, rekening),
--          mencabut akses SELECT langsung ke tabel dasar bagi peran laporan, dan membuktikan
--          peran laporan hanya dapat membaca data tersamar sesuai penyewanya.
-- Dipilih: membuat view lab11.v_pelanggan_samaran milik postgres (security_invoker = false)
--          dengan filter tenant_id aktif agar isolasi penyewa tetap jalan, lalu mencabut
--          SELECT pada tabel dasar lab11.pelanggan dari app_read dalam transaksi ROLLBACK.
-- Alternatif: memakai security_invoker = true sambil mencabut SELECT tabel dasar dari app_read;
--             tidak dipilih karena security_invoker mengecek hak tabel dasar memakai peran
--             pemanggil sehingga akses ke view ikut tertolak (permission denied).

BEGIN;
  -- 1. Buat view penyamaran (hak tabel dasar dievaluasi sebagai pemilik view, filter tenant tetap aktif)
  CREATE VIEW lab11.v_pelanggan_samaran AS
  SELECT
    id,
    tenant_id,
    nama,
    left(nik, 4) || repeat('*', 8) || right(nik, 4) AS nik_samaran,
    left(split_part(surel, '@', 1), 2) || '***@' || split_part(surel, '@', 2) AS surel_samaran,
    kota,
    saldo,
    repeat('*', greatest(length(rekening) - 4, 0)) || right(rekening, 4) AS rekening_samaran
  FROM lab11.pelanggan
  WHERE tenant_id = NULLIF(current_setting('app.tenant', true), '')::integer;

  -- 2. Terapkan hak minimum: cabut SELECT tabel dasar dari app_read, beri SELECT hanya ke view
  REVOKE SELECT ON lab11.pelanggan FROM app_read;
  GRANT SELECT ON lab11.v_pelanggan_samaran TO app_read;

  -- 3. Uji positif sebagai app_laporan (penyewa 1) -> berhasil membaca data tersamar:
  SET LOCAL ROLE app_laporan;
  SET LOCAL app.tenant = '1';

  SELECT id, nama, nik_samaran, surel_samaran, kota, rekening_samaran
  FROM lab11.v_pelanggan_samaran
  ORDER BY id
  LIMIT 3;

  -- 4. Uji negatif sebagai app_laporan -> baca langsung tabel dasar ditolak:
  SELECT id, nama, nik, rekening
  FROM lab11.pelanggan
  LIMIT 1;
ROLLBACK;