DO $$
DECLARE
    v_sisa integer;
BEGIN
    SELECT count(*) INTO v_sisa
    FROM lab4.film f
    WHERE NOT EXISTS (
        SELECT 1 FROM lab4.harga_film h
        WHERE h.film_id = f.film_id AND h.wilayah = 'ID'
    );
    IF v_sisa > 0 THEN
        RAISE EXCEPTION 'Backfill belum lengkap, sisa: %', v_sisa;
    END IF;
END $$;