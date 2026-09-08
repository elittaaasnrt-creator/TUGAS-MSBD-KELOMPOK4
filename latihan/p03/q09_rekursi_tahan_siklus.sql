-- Diminta: Membuat query rekursif yang tidak *crash* meski data memiliki siklus (infinite loop).
-- Dipilih: Penambahan array penanda jalur (path) dan pengecekan ANY() untuk menghentikan iterasi jika ID sudah pernah dikunjungi.
-- Alternatif: Klausa CYCLE bawaan PostgreSQL; tidak dipilih karena manipulasi array manual lebih melatih pemahaman logika memori rekursi.

WITH RECURSIVE hierarki_aman AS (
    SELECT pegawai_id, nama, atasan_id, 1 AS level, ARRAY[pegawai_id] AS jalur_id
    FROM pegawai
    WHERE nama = 'Rina'
    UNION ALL
    SELECT p.pegawai_id, p.nama, p.atasan_id, h.level + 1, h.jalur_id || p.pegawai_id
    FROM pegawai p
    JOIN hierarki_aman h ON p.atasan_id = h.pegawai_id
    WHERE NOT (p.pegawai_id = ANY(h.jalur_id))
)
SELECT pegawai_id, nama, atasan_id, level FROM hierarki_aman;