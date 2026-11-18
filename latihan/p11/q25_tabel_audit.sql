-- Diminta: buat tabel jejak_audit dan trigger rekam_audit memakai session_user;
--          jangan beri GRANT INSERT ke peran aplikasi.
-- Dipilih: fungsi trigger SECURITY DEFINER milik postgres/skema_owner dengan
--          session_user, serta mencabut semua hak langsung peran aplikasi atas jejak_audit.
-- Alternatif: memakai current_user atau memberi INSERT ke app_write; tidak dipilih
--             karena current_user pada SECURITY DEFINER selalu bernilai pemilik fungsi,
--             dan hak INSERT langsung memungkinkan aplikasi memalsukan catatan audit.

CREATE TABLE IF NOT EXISTS lab11.jejak_audit (
    id bigserial PRIMARY KEY,
    waktu timestamptz NOT NULL DEFAULT now(),
    pelaku text NOT NULL,
    tabel text NOT NULL,
    aksi text NOT NULL,
    kunci text,
    nilai_lama jsonb,
    nilai_baru jsonb
);

CREATE OR REPLACE FUNCTION lab11.rekam_audit()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = lab11, pg_temp
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO lab11.jejak_audit (pelaku, tabel, aksi, kunci, nilai_baru)
        VALUES (session_user, TG_TABLE_NAME, TG_OP, NEW.id::text, to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO lab11.jejak_audit (pelaku, tabel, aksi, kunci, nilai_lama, nilai_baru)
        VALUES (session_user, TG_TABLE_NAME, TG_OP, NEW.id::text, to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO lab11.jejak_audit (pelaku, tabel, aksi, kunci, nilai_lama)
        VALUES (session_user, TG_TABLE_NAME, TG_OP, OLD.id::text, to_jsonb(OLD));
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_pelanggan ON lab11.pelanggan;
CREATE TRIGGER trg_audit_pelanggan
AFTER INSERT OR UPDATE OR DELETE ON lab11.pelanggan
FOR EACH ROW EXECUTE FUNCTION lab11.rekam_audit();

REVOKE ALL ON lab11.jejak_audit FROM PUBLIC, app_read, app_write, app_laporan, app_analitik, app_portal;
REVOKE ALL ON SEQUENCE lab11.jejak_audit_id_seq FROM PUBLIC, app_read, app_write, app_laporan, app_analitik, app_portal;
GRANT SELECT ON lab11.jejak_audit TO app_auditor;

-- HASIL:
-- CREATE TABLE
-- CREATE FUNCTION
-- CREATE TRIGGER
-- REVOKE
-- GRANT
-- Penjelasan: satu-satunya jalur penulisan ke jejak_audit adalah melalui trigger
-- SECURITY DEFINER saat DML terjadi pada tabel target. Dengan mencabut hak langsung
-- dari peran aplikasi dan memakai session_user, pelaku asli tetap tercatat akurat
-- dan aplikasi tidak dapat menyisipkan, mengubah, atau menghapus jejak auditnya sendiri.