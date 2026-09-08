-- Diminta: Menampilkan hierarki pegawai, level kedalaman, dan jalur jabatan.
-- Dipilih: Recursive CTE dengan anchor atasan_id IS NULL untuk memulai dari pucuk pimpinan terbawah.
-- Alternatif: Self-join biasa; tidak dipilih karena tidak bisa menangani kedalaman hierarki yang tidak diketahui batasnya.

WITH RECURSIVE hierarki AS (
    SELECT pegawai_id, nama, atasan_id, 1 AS level, nama::text AS jalur
    FROM pegawai
    WHERE atasan_id IS NULL
    UNION ALL
    SELECT p.pegawai_id, p.nama, p.atasan_id, h.level + 1, h.jalur || ' > ' || p.nama
    FROM pegawai p
    JOIN hierarki h ON p.atasan_id = h.pegawai_id
)
SELECT * FROM hierarki ORDER BY level, pegawai_id;