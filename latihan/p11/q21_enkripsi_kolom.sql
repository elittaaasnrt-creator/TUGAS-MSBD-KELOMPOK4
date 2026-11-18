-- Diminta: menerapkan enkripsi tingkat kolom (bytea) menggunakan pgp_sym_encrypt dan
--          pgp_sym_decrypt dengan kunci yang disuntikkan dari luar basis data (variabel sesi),
--          serta menguji pembacaan tanpa kunci, dengan kunci sah, dan dengan kunci salah.
-- Dipilih: menambahkan kolom nik_enc (bytea) dan rekening_enc (bytea), mengisi ciphertext
--          menggunakan kunci sesi app.enc_key, lalu membandingkan hasil SELECT mentah vs
--          dekripsi menggunakan pgp_sym_decrypt dalam transaksi ROLLBACK agar skema tetap bersih.
-- Alternatif: menyimpan kunci enkripsi di tabel konfigurasi atau menanamkannya langsung di
--             dalam definisi VIEW; tidak dipilih karena siapa pun yang memperoleh akses baca
--             basis data atau file cadangan (pg_dump) otomatis ikut mendapatkan kuncinya.

BEGIN;
  -- 1. Tambah kolom bytea untuk menyimpan ciphertext dan suntikkan kunci dari aplikasi
  ALTER TABLE lab11.pelanggan
    ADD COLUMN nik_enc bytea,
    ADD COLUMN rekening_enc bytea;

  SET LOCAL app.enc_key = 'KunciRahasia-KMS-2026!';

  UPDATE lab11.pelanggan
  SET nik_enc      = pgp_sym_encrypt(nik, current_setting('app.enc_key')),
      rekening_enc = pgp_sym_encrypt(rekening, current_setting('app.enc_key'))
  WHERE id <= 3;

  -- 2. Pembacaan langsung tanpa dekripsi (tampilan saat dump/storage bocor tanpa kunci):
  SELECT id,
         nama,
         left(encode(nik_enc, 'hex'), 32) || '...' AS nik_ciphertext_hex,
         left(encode(rekening_enc, 'hex'), 32) || '...' AS rekening_ciphertext_hex
  FROM lab11.pelanggan
  WHERE id <= 3
  ORDER BY id;

  -- 3. Dekripsi sah menggunakan kunci sesi yang tepat:
  SELECT id,
         nama,
         pgp_sym_decrypt(nik_enc, current_setting('app.enc_key'))      AS nik_terdekripsi,
         pgp_sym_decrypt(rekening_enc, current_setting('app.enc_key')) AS rekening_terdekripsi
  FROM lab11.pelanggan
  WHERE id <= 3
  ORDER BY id;

  -- 4. Uji negatif: dekripsi memakai kunci yang salah -> ditolak pgcrypto:
  SELECT pgp_sym_decrypt(nik_enc, 'KunciSalah123') AS coba_kunci_salah
  FROM lab11.pelanggan
  WHERE id = 1;
ROLLBACK;