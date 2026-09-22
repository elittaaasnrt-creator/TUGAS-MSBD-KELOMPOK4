-- Diminta: memanggil procedure dengan p_amount negatif dan membuktikan tidak ada baris baru masuk (rollback).
-- Dipilih: mengandalkan RAISE EXCEPTION di dalam procedure (validasi p_amount <= 0) yang otomatis membatalkan seluruh statement dalam CALL tersebut, termasuk INSERT rental yang sudah sempat jalan.
-- Alternatif: menaruh validasi hanya di domain positive_amount (Q6); tidak dipilih di sini karena soal Q3 spesifik menguji jalur RAISE EXCEPTION di procedure, bukan constraint domain.

SELECT count(*) AS jumlah_sebelum FROM lab5.rental_tx;

CALL lab5.process_rental(1, 1, 1, -4.99);

SELECT count(*) AS jumlah_sesudah FROM lab5.rental_tx;