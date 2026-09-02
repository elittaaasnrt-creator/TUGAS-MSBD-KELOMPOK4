ALTER TABLE anggota
    ALTER COLUMN kuota_maksimal SET NOT NULL;

ALTER TABLE anggota
    ADD CONSTRAINT ck_kuota_positif CHECK (kuota_maksimal > 0);