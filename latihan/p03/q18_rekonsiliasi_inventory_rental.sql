-- Diminta: Menampilkan film_id yang ada di inventory tapi tidak pernah dirental, serta sebaliknya dalam satu hasil.
-- Dipilih: Kombinasi EXCEPT dan UNION ALL dengan penambahan kolom label konstan 'keterangan' untuk menandai arah perbedaan data.
-- Alternatif: Menggunakan FULL OUTER JOIN dengan kondisi WHERE i.inventory_id IS NULL OR r.inventory_id IS NULL; tidak dipilih karena penggunaan operator himpunan (EXCEPT) lebih tegas mengekspresikan logika diferensiasi himpunan data.

(
  SELECT 
    i.film_id, 
    'Ada di Inventory, Tidak di Rental' AS keterangan
  FROM inventory i
  EXCEPT
  SELECT 
    i.film_id, 
    'Ada di Inventory, Tidak di Rental' AS keterangan
  FROM inventory i
  JOIN rental r ON i.inventory_id = r.inventory_id
)
UNION ALL
(
  SELECT 
    i.film_id, 
    'Ada di Rental, Tidak di Inventory' AS keterangan
  FROM rental r
  JOIN inventory i ON r.inventory_id = i.inventory_id
  EXCEPT
  SELECT 
    i.film_id, 
    'Ada di Rental, Tidak di Inventory' AS keterangan
  FROM inventory i
);