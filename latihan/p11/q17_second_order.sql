-- Diminta: membuat fungsi laporan_kota_rentan dan laporan_kota_aman, menyimpan nilai status
--          berbahaya lewat jalur INSERT yang aman, memanggil kedua fungsi laporan, lalu
--          membandingkan hasilnya dan menjelaskan mengapa pertahanan pintu masuk tidak menolong.
-- Dipilih: menyimpan payload "' OR '1'='1" lewat PREPARE/EXECUTE (jalur masuk aman), lalu
--          membandingkan fungsi PL/pgSQL yang menyambung string EXECUTE secara langsung vs
--          fungsi yang memakai klausa USING $1, di dalam transaksi ROLLBACK agar data tetap bersih.
-- Alternatif: mengandalkan sanitasi atau parameterisasi hanya saat INSERT di pintu masuk;
--             tidak dipilih karena data yang sudah tersimpan di tabel dapat menjadi vektor
--             serangan saat dibaca ulang oleh prosedur atau laporan di kemudian hari.

CREATE OR REPLACE FUNCTION lab11.laporan_kota_rentan(p_transaksi_id int)
RETURNS bigint
LANGUAGE plpgsql
AS $$
DECLARE
  v_status text;
  v_total  bigint;
BEGIN
  -- Ambil nilai status yang sudah tersimpan di basis data
  SELECT status INTO v_status
  FROM lab11.transaksi
  WHERE id = p_transaksi_id;

  -- RENTAN: nilai dari kolom tabel disambung langsung ke string SQL dinamis
  EXECUTE 'SELECT count(*) FROM lab11.transaksi t '
       || 'JOIN lab11.pelanggan p ON p.id = t.pelanggan_id '
       || 'WHERE t.status = ''' || v_status || ''''
  INTO v_total;

  RETURN v_total;
END $$;

CREATE OR REPLACE FUNCTION lab11.laporan_kota_aman(p_transaksi_id int)
RETURNS bigint
LANGUAGE plpgsql
AS $$
DECLARE
  v_status text;
  v_total  bigint;
BEGIN
  SELECT status INTO v_status
  FROM lab11.transaksi
  WHERE id = p_transaksi_id;

  -- AMAN: nilai dari tabel tetap diperlakukan sebagai parameter ($1) lewat USING
  EXECUTE 'SELECT count(*) FROM lab11.transaksi t '
       || 'JOIN lab11.pelanggan p ON p.id = t.pelanggan_id '
       || 'WHERE t.status = $1'
  USING v_status
  INTO v_total;

  RETURN v_total;
END $$;

BEGIN;
  -- 1. Simpan payload berbahaya lewat jalur INSERT berparameter (aman saat masuk)
  PREPARE ins_transaksi_aman (int, int, int, numeric, text) AS
    INSERT INTO lab11.transaksi (id, pelanggan_id, tenant_id, jumlah, status, dibuat_pada)
    VALUES ($1, $2, $3, $4, $5, now());

  EXECUTE ins_transaksi_aman(999999, 1, 1, 50000, ''' OR ''1''=''1');
  DEALLOCATE ins_transaksi_aman;

  -- 2. Panggil kedua fungsi laporan dan bandingkan jumlah baris yang dikembalikan
  SELECT lab11.laporan_kota_rentan(999999) AS hasil_laporan_rentan,
         lab11.laporan_kota_aman(999999)   AS hasil_laporan_aman;
ROLLBACK; -- Hapus baris uji 999999 agar tabel transaksi tetap utuh 120000 baris