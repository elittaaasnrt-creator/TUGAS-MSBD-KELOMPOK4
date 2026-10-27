# Latihan P09 - Menguji Transaksi dan Kendali Konkurensi

**Mata kuliah:** Manajemen Sistem Basis Data · **Kelompok 4**
**Cabang:** `latihan/p09-transaksi-konkurensi`

## Tujuan

Mendemonstrasikan transaksi dengan dua sesi PostgreSQL 17 dan menjelaskan hasilnya: ACID, anomali konkurensi (dirty read, non-repeatable read, phantom read, lost update, write skew), isolation level, MVCC, row lock, deadlock, SKIP LOCKED/NOWAIT, SERIALIZABLE, dan strategi retry untuk SQLSTATE 40001 dan 40P01.

## Anggota dan Pembagian

| Nama                       | NIM       | Bagian                                                      |
| -------------------------- | --------- | ----------------------------------------------------------- |
| Jelita Hati Sinurat        | 251402141 | `q00_setup.sql`, Q1-Q5, README, kerangka laporan, tautan MR |
| M. Ismail Dzakwan Rangkuti | 251402014 | Q6-Q11, Q30, `bukti/isolation-level.md`                     |
| Agi Aginta Sembiring       | 251402059 | Q12-Q17, Q32                                                |
| M. Azkha Amorie            | 251402092 | Q18-Q23, lingkungan, `bukti/deadlock.md`                    |
| Syifa Nazira               | 251402126 | Q24-Q29, Q31, `bukti/serializable.md`, pengungkapan AI      |

## Struktur Folder

```
latihan/p09/
├── README.md
├── laporan.md
├── q00_setup.sql
├── q01_q32_transaksi.sql
└── bukti/
    ├── isolation-level.md
    ├── deadlock.md
    ├── serializable.md
    └── hasil-sesi.txt
```

## Cara Menjalankan

1. Pastikan container PostgreSQL 17 berjalan (`msbd-pg`).
2. Buka dua terminal, masing-masing masuk ke psql sebagai Sesi A dan Sesi B:
   ```
   docker exec -it msbd-pg psql -U msbd -d pagila
   ```
3. Jalankan setup (juga dipakai untuk mereset data antar eksperimen), dari PowerShell biasa:
   ```
   Get-Content latihan\p09\q00_setup.sql | docker exec -i msbd-pg psql -U msbd -d pagila
   ```
4. Jalankan `q01_q32_transaksi.sql` per bagian sesuai urutan dan label `[A]` / `[B]`.
5. Catat urutan perintah, hasil `SELECT`, status COMMIT/ROLLBACK, dan SQLSTATE jika ada error.

## Catatan

- Semua objek ada di skema `lab9`. Tabel Pagila dan skema latihan lain tidak diubah.
- Timeout tidak diubah secara global; pengujian timeout memakai `SET LOCAL` di dalam transaksi.
- Transaksi yang gagal di-ROLLBACK sebelum eksperimen berikutnya, dan data dikembalikan ke kondisi awal (Ani 1.000.000, Budi 1.000.000).

## Laporan

Jawaban Q1-Q32, bukti, tabel ringkasan anomali, kesimpulan, dan pengungkapan penggunaan AI ada di [`laporan.md`](laporan.md).
