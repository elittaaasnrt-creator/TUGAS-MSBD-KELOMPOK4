-- Diminta: menyebutkan tiga cara isolasi RLS masih bisa gagal beserta satu kalimat perbaikannya,
--          dan membuktikan minimal satu celah dengan keluaran nyata.
-- Dipilih: membuktikan Celah 1 (kebijakan tambahan yang terlalu longgar digabung dengan logika OR)
--          di dalam blok transaksi ROLLBACK agar data asli lab11.pelanggan tetap utuh.
-- Alternatif: mengubah atau menyisipkan data secara permanen; tidak dipilih karena melanggar
--             aturan non-destruktif terhadap data dasar lab11.

-- Tiga cara isolasi RLS masih bisa gagal:
-- 1. Kebijakan permisif tambahan yang terlalu longgar (misalnya FOR INSERT WITH CHECK (true)):
--    PostgreSQL menggabungkan seluruh kebijakan permisif dengan logika OR sehingga satu kebijakan
--    longgar membatalkan kebijakan ketat; perbaikannya adalah mengganti ekspresi true dengan
--    pemeriksaan tenant_id yang sah atau menggunakan kebijakan bertipe RESTRICTIVE.
-- 2. Kebocoran konteks penyewa di kolam koneksi atau penyetelan app.tenant dari input tak tervalidasi:
--    Jika aplikasi memakai SET tanpa LOCAL atau mempercayai parameter tenant dari klien tanpa
--    validasi token sesi sisi server, penyewa dapat menyamar; perbaikannya adalah selalu menyetel
--    konteks menggunakan set_config('app.tenant', ..., true) berdasarkan klaim sesi terautentikasi.
-- 3. Akses melalui VIEW tanpa security_invoker atau fungsi SECURITY DEFINER milik pemilik tabel:
--    Keduanya dieksekusi dengan hak pemilik objek (bukan pemanggil) sehingga kebijakan RLS peran
--    aplikasi dapat dilewati; perbaikannya adalah mengaktifkan security_invoker = true pada view
--    penyewa dan menghindari SECURITY DEFINER untuk query data multi-penyewa.

-- === BUKTI NYATA CELAH 1: Kebijakan longgar menggugurkan kebijakan ketat (logika OR) ===
BEGIN;
  -- Tambah kebijakan longgar sementara (misalnya untuk keperluan impor data)
  CREATE POLICY p_impor_longgar ON lab11.pelanggan
    FOR INSERT TO app_write
    WITH CHECK (true);

  SET LOCAL ROLE app_portal;
  SET LOCAL app.tenant = '1';

  -- Penyewa 1 berhasil menyisipkan baris atas nama Penyewa 2 (tenant_id = 2)
  INSERT INTO lab11.pelanggan (id, tenant_id, nama, nik, surel, lahir, kota, saldo, rekening, dibuat_pada)
  VALUES (99999, 2, 'Penyusup Tenant 2', '1271000000099999', 'susup@contoh.test',
          DATE '1995-05-05', 'Medan', 500000, '9999999999', now());

  -- Terbukti tersisip (INSERT 0 1), meski tidak terlihat oleh penyewa 1 saat SELECT (0 baris)
  SELECT count(*) AS terlihat_oleh_penyewa1
  FROM lab11.pelanggan
  WHERE id = 99999;
ROLLBACK; -- Membatalkan kebijakan longgar dan baris uji agar tabel kembali bersih