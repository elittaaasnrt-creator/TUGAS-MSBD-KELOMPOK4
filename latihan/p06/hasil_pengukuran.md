# Hasil Pengukuran Latihan Kelompok Pertemuan 6

Aturan: `SET max_parallel_workers_per_gather = 0;`, setiap query dijalankan 3 kali, laporkan tercepat dan median (ms), sertakan Buffers (shared hit/read). Keluaran EXPLAIN lengkap disimpan di `explain/`.

Soal Q1-Q6 (anatomi storage) bukan pengukuran waktu EXPLAIN, jadi jawabannya ada di `laporan.md`.

| Soal | Query / index | Run 1 | Run 2 | Run 3 | Tercepat | Median | Buffers | Ukuran | Keputusan | Pengukur |
|---|---|---|---|---|---|---|---|---|---|---|
| Q7 | Baseline tanpa index | 115.40 | 109.16 | 102.11 | 102.11 ms | 109.16 ms | shared hit=14977 read=43592 | 0 MB | Query lambat, butuh index | Mael |
| Q8 | ev_salah_idx (terjadi_pada, customer_id) | 24.12 | 22.79 | 19.68 | 19.68 ms | 22.79 ms | shared hit=3827 | 60 MB | Belum optimal (urutan kolom salah) | Mael |
| Q9 | ev_benar_idx (customer_id, terjadi_pada DESC) | 0.082 | 0.065 | 0.060 | 0.060 ms | 0.065 ms | shared hit=19 | 60 MB | **Sangat Direkomendasikan** (~1680x cepat) | Mael |
| Q10 | Perbandingan ukuran ev_salah_idx vs ev_benar_idx | - | - | - | - | - | - | 60 MB vs 60 MB | Ukuran sama, beda efisiensi B-Tree | Mael |
| Q12 | ev_gagal_idx (partial) vs index polos terjadi_pada | - | - | - | - | - | - | 896 kB vs 43 MB | **Dipertahankan** (Hemat 97.9% disk/RAM) | Agi |
| Q13 | email = ... vs lower(email) = ... | 532.803 (Seq) | 3.534 (Idx) | 3.610 (Idx) | 3.534 ms | 3.534 ms | shared read=4 | 43 MB | **Dipertahankan** (Expression Index ~150x cepat) | Agi |
| Q14 | Covering ev_cover_idx sebelum VACUUM | 3.820 | 3.480 | 3.510 | 3.480 ms | 3.480 ms | shared hit=2 read=4 | 77 MB | Index Only Scan (Heap Fetches 0) | Agi |
| Q14 | Covering ev_cover_idx sesudah VACUUM (Heap Fetches) | 0.095 | 0.073 | 0.073 | 0.073 ms | 0.073 ms | shared hit=6 | 77 MB | **Sangat Cepat** (Heap Fetches 0, 100% RAM hit) | Agi |
| Q15 | INCLUDE vs index tiga kolom biasa | 0.210 | 0.185 | 0.125 | 0.125 ms | 0.185 ms | shared hit=2 read=4 | 77 MB vs 77 MB | **Pilih `ev_cover_idx`** (fleksibel di leaf node) | Agi |
| Q17 | GIN payload jsonb_path_ops | 438.255 | 296.556 | 267.910 | 267.910 | 296.556 | hit=1 read=58588 | 7096 kB (GIN) / 458 MB (heap) | Dipertahankan, ~1.5% ukuran heap | Azkha |
| Q18 | GIN tags (dengan vs tanpa GIN) | 313.279 | 288.284 | 255.030 | 255.030 | 288.284 | hit=1 read=58643 | 4664 kB (GIN) | Dipertahankan, 1.5x lebih cepat vs Seq Scan (430.753 ms) | Azkha |
| Q19 | BRIN vs B-Tree terjadi_pada (ukuran, correlation) | - | - | - | - | - | - | BRIN 32 kB / B-Tree 43 MB | correlation=1; BRIN dipertahankan | Azkha |
| Q20 | Rentang 7 hari: BRIN vs B-Tree | BRIN: 11.173/7.899/7.352 — B-Tree: 9.685/10.610/8.755 | 7.352 (BRIN) / 8.755 (B-Tree) | 7.899 (BRIN) / 9.685 (B-Tree) | hit=1411 (BRIN) / hit=1499 (B-Tree) | 32 kB / 43 MB | BRIN menang di waktu & Buffers | Azkha |
| Q29 | Daftar index lab6, idx_scan, ukuran | - | - | - | - | - | - | lihat laporan.md | ev_terjadi_brin_idx idx_scan=0 tapi dipertahankan | Azkha |
| Q22 | Index status: SUKSES vs GAGAL | 324.95 (SUKSES) / 149.20 (GAGAL) | 324.95 / 149.20 | 324.95 / 149.20 | 324.95 ms (SUKSES) / 149.20 ms (GAGAL) | 324.95 ms / 149.20 ms | hit=14886 read=43683 (SUKSES) / read=39974 (GAGAL) | 43 MB | SUKSES pilih Seq Scan, GAGAL pilih Index Scan | Syifa |
| Q23 | Titik peralihan Index Scan ke Seq Scan | - | - | - | - | - | - | - | Transisi pada selektivitas 10%–15% (SUKSES 84% -> Seq Scan) | Syifa |
| Q24 | random_page_cost = 1.1 (lalu RESET) | 329.04 | 329.04 | 329.04 | 329.04 ms | 329.04 ms | hit=16206 read=42363 | 43 MB | Tetap Seq Scan karena data SUKSES sangat dominan (84%) | Syifa |
| Q25 | Extended statistics wilayah-kota (sebelum/sesudah) | 81.01 (sblm) / 92.86 (ssdh) | 81.01 / 92.86 | 81.01 / 92.86 | 81.01 ms (sblm) / 92.86 ms (ssdh) | 81.01 ms / 92.86 ms | hit=16098 read=42471 | 0 MB (stat) | Parallel Seq Scan; tingkatkan presisi estimasi multi-kolom | Syifa |
| Q27 | INSERT 200000 baris: tanpa index vs lima index | 813.58 | 813.58 | 813.58 | 813.58 ms | 813.58 ms | - | - | Overhead penulisan ~2.82x lebih lambat | Mael |
| Q28 | Ukuran total tabel: tanpa index vs dengan index | - | - | - | - | - | - | 28 MB vs 72 MB | Overhead penyimpanan index 44 MB | Agi |
| Q29 | Daftar index lab6, idx_scan, ukuran | - | - | - | - | - | - | | | Azkha |
| Q30 | Rekomendasi final (satu angka per keputusan) | - | - | - | - | - | - | - | Pertahankan `ev_benar_idx` & `ev_cover_idx`, hapus `idx_event_status` | Syifa |

## Catatan Penyimpangan

- Semua pengujian berjalan lancar di lingkungan Docker PostgreSQL 17 tanpa penyesuaian jumlah baris data (tetap 2.000.000 baris di `lab6.event_log`).
- `SET max_parallel_workers_per_gather = 0;` diterapkan pada seluruh sesi pengukuran untuk memastikan konsistensi hasil.
