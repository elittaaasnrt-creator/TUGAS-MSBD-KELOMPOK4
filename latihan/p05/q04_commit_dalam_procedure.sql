-- Diminta: procedure yang menjalankan COMMIT setelah INSERT pertama, dipanggil dari Python di dalam blok transaksi eksplisit, untuk membuktikan galat invalid transaction termination.
-- Dipilih: salinan terpisah (process_rental_bad_commit) agar procedure asli (Q2/Q3) tidak berubah dan tetap bisa dipakai di soal-soal berikutnya.
-- Alternatif: memodifikasi process_rental langsung; tidak dipilih karena akan merusak Q3 dan Q5 yang bergantung pada procedure asli.

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

  COMMIT;  -- sengaja ditambahkan untuk membuktikan galat

  INSERT INTO lab5.payment_tx (rental_id, amount)
  VALUES (v_rental_id, p_amount);
END;
$$;