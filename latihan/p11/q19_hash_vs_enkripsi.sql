-- Diminta: membandingkan fungsi hash satu arah (crypt + gen_salt) untuk kata sandi
--          dengan enkripsi simetris dua arah (pgp_sym_encrypt / pgp_sym_decrypt) untuk
--          data identitas yang perlu dibaca kembali, serta membuktikan hasil keduanya.
-- Dipilih: mendemonstrasikan pencocokan kata sandi memakai bcrypt (gen_salt('bf')) dan
--          enkripsi-dekripsi NIK menggunakan pgp_sym_encrypt/decrypt dalam transaksi ROLLBACK
--          agar data asli lab11.akun dan lab11.pelanggan tidak berubah.
-- Alternatif: mengenkripsi kata sandi dengan pgp_sym_encrypt atau menghash NIK dengan SHA-256;
--             tidak dipilih karena kata sandi yang dapat didekripsi berisiko bocor saat kunci
--             terungkap, sedangkan NIK yang di-hash satu arah tidak dapat dipulihkan untuk
--             keperluan administrasi yang sah.

-- 1. Lihat sampel kondisi awal pada lab11.akun (kata sandi masih tersimpan mentah/plaintext)
SELECT id, username, kata_sandi AS sandi_awal
FROM lab11.akun
ORDER BY id
LIMIT 3;

BEGIN;
  -- 2. HASH SATU ARAH (Bcrypt dengan salt acak per baris untuk kata_sandi)
  --    Dua baris dengan sandi identik tetap menghasilkan hash berbeda karena salt acak.
  UPDATE lab11.akun
  SET kata_sandi = crypt('rahasia123', gen_salt('bf', 8))
  WHERE id IN (1, 2);

  SELECT id,
         username,
         kata_sandi AS hash_tersimpan,
         (kata_sandi = crypt('rahasia123', kata_sandi)) AS verifikasi_sandi_benar,
         (kata_sandi = crypt('salah999', kata_sandi))   AS verifikasi_sandi_salah
  FROM lab11.akun
  WHERE id IN (1, 2)
  ORDER BY id;

  -- 3. ENKRIPSI SIMETRIS DUA ARAH (PGP simetris untuk kolom NIK yang perlu dipulihkan)
  WITH uji_enkripsi AS (
    SELECT id,
           nama,
           nik AS nik_asli,
           pgp_sym_encrypt(nik, 'kunci-master-lab11') AS nik_terenkripsi
    FROM lab11.pelanggan
    WHERE id = 1
  )
  SELECT id,
         nama,
         encode(nik_terenkripsi, 'base64') AS ciphertext_base64,
         pgp_sym_decrypt(nik_terenkripsi, 'kunci-master-lab11') AS hasil_dekripsi
  FROM uji_enkripsi;
ROLLBACK;