-- Diminta: menunjukkan satu bagian query yang tidak bisa diparameterkan (nama kolom atau
--          arah urut), menanganinya dengan daftar putih tertutup, dan membuktikan nilai di
--          luar daftar ditolak.
-- Dipilih: memetakan parameter pengurutan melalui dictionary whitelist tertutup di aplikasi
--          (KOLOM dan ARAH) serta membuktikan sisi basis data menolak pengenal tidak sah
--          lewat fungsi format('%I', ...) pada blok PL/pgSQL.
-- Alternatif: menyisipkan nama kolom atau arah urut langsung ke string SQL maupun mencoba
--             memakai placeholder parameter ($1) pada klausa ORDER BY; tidak dipilih karena
--             SQL tidak mengizinkan parameterisasi nama pengenal/kata kunci, sedangkan
--             penyambungan string membuka celah SQL injection lewat pengenal.

-- Contoh implementasi daftar putih tertutup di Python (aplikasi):
-- KOLOM = {"nama": "nama", "kota": "kota", "terbaru": "dibuat_pada"}
-- ARAH  = {"naik": "ASC", "turun": "DESC"}
-- if kolom not in KOLOM or arah not in ARAH:
--     raise ValueError("parameter pengurutan tidak dikenal")

-- Pembuktian di PostgreSQL:
-- 1. Nilai di dalam daftar putih (kolom = 'kota', arah = 'DESC') -> berhasil dieksekusi:
DO $$
DECLARE
  v_kolom text := 'kota';
  v_arah  text := 'DESC';
  v_sql   text;
  v_contoh text;
BEGIN
  IF v_kolom NOT IN ('nama', 'kota', 'dibuat_pada') OR v_arah NOT IN ('ASC', 'DESC') THEN
    RAISE EXCEPTION 'parameter pengurutan tidak dikenal: % %', v_kolom, v_arah;
  END IF;

  v_sql := format(
    'SELECT nama || '' ('' || kota || '')'' FROM lab11.pelanggan WHERE tenant_id = 1 ORDER BY %I %s LIMIT 1',
    v_kolom, v_arah
  );
  EXECUTE v_sql INTO v_contoh;
  RAISE NOTICE 'Validasi daftar putih berhasil -> contoh baris: %', v_contoh;
END $$;

-- 2. Uji negatif: nilai di luar daftar putih (percobaan injeksi pada kolom urut) -> ditolak:
DO $$
DECLARE
  v_kolom text := 'nama; DROP TABLE lab11.pelanggan; --';
  v_arah  text := 'ASC';
BEGIN
  IF v_kolom NOT IN ('nama', 'kota', 'dibuat_pada') OR v_arah NOT IN ('ASC', 'DESC') THEN
    RAISE EXCEPTION 'parameter pengurutan tidak dikenal: %', v_kolom;
  END IF;
END $$;