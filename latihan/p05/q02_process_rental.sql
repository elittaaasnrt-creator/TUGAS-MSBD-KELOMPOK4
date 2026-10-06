-- Diminta: menyalin procedure lab5.process_rental dari materi kuliah, membuktikan satu pemanggilan menghasilkan baris di rental_tx dan payment_tx.
-- Dipilih: PROCEDURE dengan parameter INOUT p_rental_id karena procedure tidak bisa RETURN nilai seperti function; INOUT adalah cara procedure "mengembalikan" hasil.
-- Alternatif: FUNCTION yang RETURN rental_id; tidak dipilih karena procedure ini melakukan dua INSERT (bukan sekadar query), dan slide dosen eksplisit menggunakan CALL + INOUT.

CREATE OR REPLACE PROCEDURE lab5.process_rental(
  IN p_customer_id  integer,
  IN p_inventory_id integer,
  IN p_staff_id     integer,
  IN p_amount       numeric(10,2),
  IN p_metadata     jsonb DEFAULT '{}'::jsonb,
  INOUT p_rental_id bigint DEFAULT NULL
) LANGUAGE plpgsql AS $$
BEGIN
  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'nilai pembayaran harus positif, diterima %', p_amount
      USING ERRCODE = '22003';   -- numeric_value_out_of_range
  END IF;

  INSERT INTO lab5.rental_tx (customer_id, inventory_id, staff_id, metadata)
  VALUES (p_customer_id, p_inventory_id, p_staff_id,
          coalesce(p_metadata, '{}'::jsonb))
  RETURNING rental_id INTO p_rental_id;

  INSERT INTO lab5.payment_tx (rental_id, amount)
  VALUES (p_rental_id, p_amount);
  -- sengaja tidak ada COMMIT: batas transaksi milik pemanggil
END;
$$;

-- uji dengan nilai sah, buktikan baris masuk ke kedua tabel
CALL lab5.process_rental(1, 1, 1, 4.99);
SELECT * FROM lab5.rental_tx;
SELECT * FROM lab5.payment_tx;
CREATE OR REPLACE PROCEDURE lab5.process_rental_bad_commit(
  IN p_customer_id  integer,
  IN p_inventory_id integer,
  IN p_staff_id     integer,
  IN p_amount       numeric(10,2)
) LANGUAGE plpgsql AS $$
DECLARE
  v_rental_id bigint;
BEGIN
  INSERT INTO lab5.rental_tx (customer_id, inventory_id, staff_id)
  VALUES (p_customer_id, p_inventory_id, p_staff_id)
  RETURNING rental_id INTO v_rental_id;

  COMMIT; -- Sengaja COMMIT internal (akan gagal di psycopg 3)

  INSERT INTO lab5.payment_tx (rental_id, amount)
  VALUES (v_rental_id, p_amount);
END;
$$;