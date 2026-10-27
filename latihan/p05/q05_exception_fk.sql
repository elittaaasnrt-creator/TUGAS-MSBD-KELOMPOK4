-- Diminta: menambahkan EXCEPTION WHEN foreign_key_violation dengan pesan lebih ramah pada process_rental.
-- Dipilih: menangkap foreign_key_violation karena ini error yang punya rencana pemulihan jelas (beri tahu pengguna ID tidak dikenal), sesuai prinsip slide 8: "tangkap hanya bila ada rencana".
-- Alternatif: menangkap semua exception dengan WHEN OTHERS; tidak dipilih karena akan menelan galat lain yang seharusnya naik ke log (slide 8: procedure yang "tidak pernah gagal" biasanya menyembunyikan kegagalan).

CREATE OR REPLACE PROCEDURE lab5.process_rental_v2(
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
      USING ERRCODE = '22003';
  END IF;

  INSERT INTO lab5.rental_tx (customer_id, inventory_id, staff_id, metadata)
  VALUES (p_customer_id, p_inventory_id, p_staff_id,
          coalesce(p_metadata, '{}'::jsonb))
  RETURNING rental_id INTO p_rental_id;

  INSERT INTO lab5.payment_tx (rental_id, amount)
  VALUES (p_rental_id, p_amount);

EXCEPTION
  WHEN foreign_key_violation THEN
    RAISE EXCEPTION 'customer, inventory, atau staff tidak dikenal'
      USING ERRCODE = '23503';
END;
$$;

-- uji dengan inventory_id yang tidak ada
CALL lab5.process_rental_v2(1, 999999, 1, 4.99);