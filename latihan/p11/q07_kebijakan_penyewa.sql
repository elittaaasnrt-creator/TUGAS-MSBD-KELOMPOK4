-- Diminta: membuat sepasang kebijakan isolasi penyewa untuk baca (app_read, app_write)
--          dan tulis (app_write) pada lab11.pelanggan yang aman dari string kosong.
-- Dipilih: CREATE POLICY dengan ekspresi nullif(current_setting('app.tenant', true), '')::int
--          pada klausa USING dan WITH CHECK.
-- Alternatif: casting langsung current_setting('app.tenant', true)::int; tidak dipilih
--             karena memicu galat invalid input syntax for type integer: "" saat koneksi dipakai ulang.

DROP POLICY IF EXISTS p_tenant_baca ON lab11.pelanggan;
DROP POLICY IF EXISTS p_tenant_tulis ON lab11.pelanggan;

CREATE POLICY p_tenant_baca ON lab11.pelanggan
  FOR SELECT TO app_read, app_write
  USING (tenant_id = nullif(current_setting('app.tenant', true), '')::int);

CREATE POLICY p_tenant_tulis ON lab11.pelanggan
  FOR ALL TO app_write
  USING      (tenant_id = nullif(current_setting('app.tenant', true), '')::int)
  WITH CHECK (tenant_id = nullif(current_setting('app.tenant', true), '')::int);

SELECT policyname, cmd, roles
FROM pg_policies
WHERE schemaname = 'lab11' AND tablename = 'pelanggan'
ORDER BY policyname;