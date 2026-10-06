# Hasil Pengukuran Latihan Kelompok Pertemuan 6

Aturan: `SET max_parallel_workers_per_gather = 0;`, setiap query dijalankan 3 kali, laporkan tercepat dan median (ms), sertakan Buffers (shared hit/read). Keluaran EXPLAIN lengkap disimpan di `explain/`.

Soal Q1-Q6 (anatomi storage) bukan pengukuran waktu EXPLAIN, jadi jawabannya ada di `laporan.md`.

| Soal | Query / index | Run 1 | Run 2 | Run 3 | Tercepat | Median | Buffers | Ukuran | Keputusan | Pengukur |
|---|---|---|---|---|---|---|---|---|---|---|
| Q7 | Baseline tanpa index | | | | | | | - | - | Mael |
| Q8 | ev_salah_idx (terjadi_pada, customer_id) | | | | | | | | | Mael |
| Q9 | ev_benar_idx (customer_id, terjadi_pada DESC) | | | | | | | | | Mael |
| Q10 | Perbandingan ukuran ev_salah_idx vs ev_benar_idx | - | - | - | - | - | - | | | Mael |
| Q12 | ev_gagal_idx (partial) vs index polos terjadi_pada | - | - | - | - | - | - | | | Agi |
| Q13 | email = ... vs lower(email) = ... | | | | | | | | | Agi |
| Q14 | Covering ev_cover_idx sebelum VACUUM | | | | | | | | | Agi |
| Q14 | Covering ev_cover_idx sesudah VACUUM (Heap Fetches) | | | | | | | | | Agi |
| Q15 | INCLUDE vs index tiga kolom biasa | | | | | | | | | Agi |
| Q17 | GIN payload jsonb_path_ops | 438.255 | 296.556 | 267.910 | 267.910 | 296.556 | hit=1 read=58588 | 7096 kB (GIN) / 458 MB (heap) | Dipertahankan, ~1.5% ukuran heap | Azkha |
| Q18 | GIN tags (dengan vs tanpa GIN) | 313.279 | 288.284 | 255.030 | 255.030 | 288.284 | hit=1 read=58643 | 4664 kB (GIN) | Dipertahankan, 1.5x lebih cepat vs Seq Scan (430.753 ms) | Azkha |
| Q19 | BRIN vs B-Tree terjadi_pada (ukuran, correlation) | - | - | - | - | - | - | BRIN 32 kB / B-Tree 43 MB | correlation=1; BRIN dipertahankan | Azkha |
| Q20 | Rentang 7 hari: BRIN vs B-Tree | BRIN: 11.173/7.899/7.352 — B-Tree: 9.685/10.610/8.755 | 7.352 (BRIN) / 8.755 (B-Tree) | 7.899 (BRIN) / 9.685 (B-Tree) | hit=1411 (BRIN) / hit=1499 (B-Tree) | 32 kB / 43 MB | BRIN menang di waktu & Buffers | Azkha |
| Q29 | Daftar index lab6, idx_scan, ukuran | - | - | - | - | - | - | lihat laporan.md | ev_terjadi_brin_idx idx_scan=0 tapi dipertahankan | Azkha |
| Q22 | Index status: SUKSES vs GAGAL | | | | | | | | | Syifa |
| Q23 | Titik peralihan Index Scan ke Seq Scan | | | | | | | | | Syifa |
| Q24 | random_page_cost = 1.1 (lalu RESET) | | | | | | | | | Syifa |
| Q25 | Extended statistics wilayah-kota (sebelum/sesudah) | | | | | | | | | Syifa |
| Q27 | INSERT 200000 baris: tanpa index vs lima index | | | | | | | | | Mael |
| Q28 | Ukuran total tabel: tanpa index vs dengan index | - | - | - | - | - | - | | | Agi |
| Q29 | Daftar index lab6, idx_scan, ukuran | - | - | - | - | - | - | | | Azkha |
| Q30 | Rekomendasi final (satu angka per keputusan) | - | - | - | - | - | - | | | Syifa |

## Catatan Penyimpangan

(Catat di sini jika ada perubahan dari instruksi, misalnya jumlah baris diturunkan, query diulang, atau index gagal dibuat.)
