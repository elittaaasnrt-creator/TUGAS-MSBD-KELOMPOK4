-- Diminta: Membentangkan array JSONB 'kontak' menjadi baris individual per kontak, serta memastikan notifikasi tanpa kontak tetap muncul.
-- Dipilih: Fungsi `jsonb_array_elements` yang dikombinasikan dengan `LEFT JOIN LATERAL ... ON true` untuk meratakan (flatten) elemen array JSONB tanpa menghilangkan baris induk yang kosong.
-- Alternatif: Menggunakan INNER JOIN LATERAL; tidak dipilih karena akan menghapus/menglengkapi baris transaksi yang kontaknya berupa array kosong (`[]`).

SELECT 
  n.payload->>'trx' AS nomor_transaksi,
  k.val->>'jenis' AS jenis_kontak,
  k.val->>'nomor' AS nomor_kontak
FROM notifikasi n
LEFT JOIN LATERAL jsonb_array_elements(n.payload->'kontak') AS k(val) ON true;