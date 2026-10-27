-- Diminta: function yang mengembalikan total pembayaran satu penyewaan.
-- Dipilih: LANGUAGE sql STABLE karena fungsi hanya membaca data, tidak mengubah state, dan hasilnya konsisten dalam satu statement.
-- Alternatif: PL/pgSQL biasa; tidak dipilih karena query-nya cukup sederhana untuk SQL murni.

CREATE OR REPLACE FUNCTION lab5.total_dibayar(p_rental_id bigint)
RETURNS numeric LANGUAGE sql STABLE AS $$
SELECT coalesce(sum(amount), 0) FROM lab5.payment_tx WHERE rental_id = p_rental_id;
$$;

-- uji coba
SELECT lab5.total_dibayar(1);