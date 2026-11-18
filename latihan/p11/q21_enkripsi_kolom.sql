-- Diminta: enkripsi kolom rekening 1000 baris dengan pgp_sym_encrypt, kunci per session.
-- Dipilih: pgp_sym_encrypt + kunci lewat setelan session (tidak ditulis di tabel).
-- Alternatif: kunci hardcode di query; tidak dipilih karena bocor ke log/riwayat.
SET app.kunci_kolom = 'kunci-lab11-jangan-dipakai-di-produksi';
ALTER TABLE lab11.pelanggan ADD COLUMN IF NOT EXISTS rekening_enc bytea;
UPDATE lab11.pelanggan
  SET rekening_enc = pgp_sym_encrypt(rekening, current_setting('app.kunci_kolom'))
WHERE id <= 1000;
SELECT count(*) AS terenkripsi FROM lab11.pelanggan WHERE rekening_enc IS NOT NULL;
SELECT id, rekening AS asli,
       pgp_sym_decrypt(rekening_enc, current_setting('app.kunci_kolom')) AS hasil_dekripsi
FROM lab11.pelanggan WHERE id = 1;
SELECT pgp_sym_encrypt('x','k') = pgp_sym_encrypt('x','k') AS sama;
-- Jawaban: ciphertext berbeda karena salt/IV acak tiap enkripsi, jadi pola nilai sama tidak terlihat.