-- Diminta: menunjukkan bagaimana kunci enkripsi dapat bocor apabila disimpan di dalam basis data
--          (misalnya pada definisi VIEW atau tabel internal) maupun melalui log query, serta
--          mendemonstrasikan langkah rotasi kunci (key rotation) untuk memulihkan keamanan.
-- Dipilih: mensimulasikan kebocoran kunci yang ditanam pada definisi VIEW (terbaca lewat katalog
--          pg_views), lalu mempraktikkan rotasi kunci bertahap (versi_kunci 1 -> 2) dengan
--          dekripsi kunci lama dan enkripsi ulang memakai kunci baru dalam transaksi ROLLBACK.
-- Alternatif: membiarkan satu kunci statis dipakai selamanya atau menyimpan kunci di tabel
--             basis data dengan pembatasan GRANT; tidak dipilih karena salinan cadangan
--             (pg_dump) dan superuser tetap membawa kunci bersama ciphertext-nya.

BEGIN;
  -- 1. Anti-pola: menanam kunci di definisi VIEW (bocor lewat pg_views / pg_dump)
  ALTER TABLE lab11.pelanggan
    ADD COLUMN nik_enc bytea,
    ADD COLUMN versi_kunci smallint DEFAULT 1;

  UPDATE lab11.pelanggan
  SET nik_enc = pgp_sym_encrypt(nik, 'KunciLama-V1-2026'),
      versi_kunci = 1
  WHERE id <= 2;

  CREATE VIEW lab11.v_pelanggan_buruk AS
  SELECT id, nama, pgp_sym_decrypt(nik_enc, 'KunciLama-V1-2026') AS nik
  FROM lab11.pelanggan;

  -- Siapa pun yang membaca definisi view langsung menemukan kunci mentahnya:
  SELECT viewname, definition AS definisi_view_membocorkan_kunci
  FROM pg_views
  WHERE schemaname = 'lab11' AND viewname = 'v_pelanggan_buruk';

  -- 2. Mitigasi saat kunci V1 dicurigai bocor: Rotasi kunci ke V2 (enkripsi ulang)
  SET LOCAL app.kunci_lama = 'KunciLama-V1-2026';
  SET LOCAL app.kunci_baru = 'KunciBaru-V2-Rotasi!';

  UPDATE lab11.pelanggan
  SET nik_enc = pgp_sym_encrypt(
                  pgp_sym_decrypt(nik_enc, current_setting('app.kunci_lama')),
                  current_setting('app.kunci_baru')
                ),
      versi_kunci = 2
  WHERE versi_kunci = 1 AND id <= 2;

  -- 3. Verifikasi data terbaca dengan kunci baru (V2) dan kunci lama tidak lagi berlaku:
  SELECT id,
         nama,
         versi_kunci,
         pgp_sym_decrypt(nik_enc, current_setting('app.kunci_baru')) AS nik_dengan_kunci_v2
  FROM lab11.pelanggan
  WHERE id <= 2
  ORDER BY id;

  -- Uji negatif: memakai kunci V1 yang bocor setelah rotasi -> gagal:
  SELECT pgp_sym_decrypt(nik_enc, current_setting('app.kunci_lama')) AS coba_kunci_bocor
  FROM lab11.pelanggan
  WHERE id = 1;
ROLLBACK;