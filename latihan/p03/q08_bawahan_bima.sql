-- Diminta: Menampilkan bawahan Bima beserta jarak level dari Bima.
-- Dipilih: Recursive CTE dengan anchor nama = 'Bima' agar pencarian terisolasi hanya pada cabang tersebut.
-- Alternatif: Menggunakan query Q7 lalu di-filter di luar; tidak dipilih karena tidak efisien memproses seluruh hierarki jika hanya butuh satu cabang.

WITH RECURSIVE bawahan AS (
    SELECT pegawai_id, nama, atasan_id, 0 AS jarak
    FROM pegawai
    WHERE nama = 'Bima'
    UNION ALL
    SELECT p.pegawai_id, p.nama, p.atasan_id, b.jarak + 1
    FROM pegawai p
    JOIN bawahan b ON p.atasan_id = b.pegawai_id
)
SELECT * FROM bawahan ORDER BY jarak, pegawai_id;