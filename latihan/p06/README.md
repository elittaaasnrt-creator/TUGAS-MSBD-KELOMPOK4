@'

# Latihan Kelompok Pertemuan 6: Mengukur Harga Sebuah Index

Manajemen Sistem Basis Data, Kelompok 4.

Latihan ini membuktikan apakah sebuah index layak dipertahankan, dengan mengukur manfaat baca, biaya tulis, dan ukuran penyimpanan menggunakan `EXPLAIN (ANALYZE, BUFFERS)`. Semua objek dibuat di skema `lab6` pada PostgreSQL 17. Index pada skema `public` (Pagila) tidak diubah.

## Anggota dan Pembagian Tugas

| Anggota                    | NIM       | GitHub                | Bagian                                                        |
| -------------------------- | --------- | --------------------- | ------------------------------------------------------------- |
| Jelita Hati Sinurat        | 251402141 | elittaaasnrt-creator  | `q00_setup.sql`, Q1-Q6 (anatomi storage), Q31, README         |
| M. Ismail Dzakwan Rangkuti | 251402014 | dzakwanrangkuti       | Q7-Q11 (baseline, B-Tree, urutan kolom), Q27                  |
| Agi Aginta Sembiring       | 251402059 | agisembiring263-pixel | Q12-Q16 (partial, expression, covering, index-only scan), Q28 |
| M. Azkha Amorie            | 251402092 | azkhaamorie           | Q17-Q21 (GIN, BRIN), Q29                                      |
| Syifa Nazira               | 251402126 | ziraa94               | Q22-Q26 (statistik, selektivitas, seq scan), Q30              |

`laporan.md` dikerjakan bersama oleh semua anggota.

## Cara Menjalankan

1. Ambil branch kerja:

```
   git fetch origin
   git checkout latihan/p06-indexing
```

2. Nyalakan database (service `postgres`, user `msbd`, database `pagila`):

```
   docker compose up -d postgres
```

3. Muat data (dua juta baris, bisa beberapa menit):

```
   Get-Content latihan\p06\q00_setup.sql -Raw | docker compose exec -T postgres psql -U msbd -d pagila
```

Jika terlalu lama, turunkan jumlah baris menjadi 500000 dan catat penyesuaiannya di `laporan.md`.

4. Jalankan berkas `.sql` bagian masing-masing, contoh:

```
   Get-Content latihan\p06\q02_anatomi_storage.sql -Raw | docker compose exec -T postgres psql -U msbd -d pagila -P pager=off -x
```

## Aturan Pengukuran

- Matikan parallel worker pada sesi ukur: `SET max_parallel_workers_per_gather = 0;`
- Jalankan setiap query tiga kali, laporkan waktu tercepat dan median.
- Selalu gunakan `EXPLAIN (ANALYZE, BUFFERS)` dan simpan keluarannya sebagai teks di `explain/`.
- Setelah memakai `SET random_page_cost`, jalankan `RESET random_page_cost;`.

## Struktur Folder

```
latihan/p06/
├── README.md
├── laporan.md
├── q00_setup.sql
├── q01_ukuran_tabel.sql
├── q02_anatomi_storage.sql ... q30_rekomendasi_index.sql
├── explain/
│   └── q07_q30_*.txt
└── hasil_pengukuran.md
```

Soal reflektif (Q1, Q6, Q11, Q16, Q21, Q26, Q31) dijawab di `laporan.md`.

## Alur Git

- Branch kerja: `latihan/p06-indexing`
- Setiap anggota commit dengan akun Git sendiri.
- Merge request dibuat setelah semua bagian selesai, tautannya dicatat di `laporan.md`.
  '@ | Set-Content latihan\p06\README.md -Encoding utf8
