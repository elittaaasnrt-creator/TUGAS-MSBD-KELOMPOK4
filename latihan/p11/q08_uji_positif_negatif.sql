-- Diminta: membuktikan isolasi penyewa bekerja sebagai app_laporan dengan konteks penyewa 1
--          melalui uji positif (data sendiri) dan uji negatif (data penyewa 2).
-- Dipilih: menjalankan kedua pengujian dalam satu blok transaksi dengan SET LOCAL ROLE
--          dan SET LOCAL app.tenant = '1'.
-- Alternatif: menguji sebagai superuser postgres; tidak dipilih karena superuser selalu
--             melewati kebijakan RLS sehingga tidak membuktikan isolasi aplikasi.

BEGIN;
  SET LOCAL ROLE app_laporan;
  SET LOCAL app.tenant = '1';

  -- Uji positif: melihat data milik penyewa 1 (harapkan 10000)
  SELECT count(*) AS terlihat_tenant1
  FROM lab11.pelanggan;

  -- Uji negatif: mencoba membaca data milik penyewa 2 secara eksplisit (harapkan 0)
  SELECT count(*) AS harus_nol
  FROM lab11.pelanggan
  WHERE tenant_id = 2;
COMMIT;