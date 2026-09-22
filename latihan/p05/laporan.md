# Laporan Latihan Kelompok Pertemuan 5

## Anggota dan Kontribusi

| Nama                       | NIM       | Kontribusi                                    | Commit |
| -------------------------- | --------- | --------------------------------------------- | ------ |
| Jelita Hati Sinurat        | 251402141 | Setup (q00) + Q1–Q5 + Reflektif A + README.md | ...    |
| M. Ismail Dzakwan Rangkuti | 251402014 | Q10–Q15 + Reflektif C                         | ...    |
| Agi Aginta Sembiring       | 251402059 | Q6–Q9 + Reflektif B                           | ...    |
| M. Azkha Amorie            | 251402092 | Q16–Q20 + Reflektif D                         | ...    |
| Syifa Nazira               | 251402126 | Q21–Q24 + Reflektif E                         | ...    |

## Q1–Q24

### Setup (q00_setup.sql)

Skema `lab5` dibuat di database **`pagila`** (bukan `latihan`, yang kosong secara default di docker-compose.yml — data DVD rental ada di `pagila`).

Verifikasi:
psycopg 3.2.13, SQLAlchemy 2.0.54, FastAPI 0.115.14
PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2)
jumlah_customer: 599

### Q1 — `lab5.total_dibayar`

```sql
CREATE OR REPLACE FUNCTION lab5.total_dibayar(p_rental_id bigint)
RETURNS numeric LANGUAGE sql STABLE AS $$
SELECT coalesce(sum(amount), 0) FROM lab5.payment_tx WHERE rental_id = p_rental_id;
$$;

Hasil: `SELECT lab5.total_dibayar(1);` → `0` (payment_tx masih kosong saat diuji).

### Q2 — `lab5.process_rental`
Procedure disalin dari materi kuliah (slide 7), memakai `INOUT p_rental_id` dan validasi `p_amount <= 0` via `RAISE EXCEPTION ... ERRCODE '22003'`.

Uji dengan nilai sah:
CALL lab5.process_rental(1, 1, 1, 4.99);

Hasil: `p_rental_id = 1`. Satu baris masuk ke `rental_tx` (status ACTIVE) dan satu baris ke `payment_tx` (amount 4.99) — membuktikan satu pemanggilan menghasilkan baris di kedua tabel.

### Q3 — Buktikan rollback
jumlah_sebelum = 1
CALL lab5.process_rental(1, 1, 1, -4.99);
→ ERROR: nilai pembayaran harus positif, diterima -4.99 (SQLSTATE 22003)
jumlah_sesudah = 1

Jumlah tidak bertambah karena validasi `p_amount <= 0` dicek di awal procedure, sebelum INSERT manapun dijalankan. Satu `CALL` diperlakukan sebagai satu unit transaksi.

### Q4 — COMMIT dalam procedure
Procedure salinan (`process_rental_bad_commit`) menambahkan `COMMIT` setelah INSERT pertama, dipanggil dari `lab5_driver.py` di dalam `with psycopg.connect(...)`.

Hasil:
GALAT: invalid transaction termination
CONTEXT: PL/pgSQL function lab5.process_rental_bad_commit(...) line 9 at COMMIT
`with psycopg.connect(...)` sudah membuka transaksi pada perintah pertama; COMMIT eksplisit di dalam procedure ditolak karena bukan pemilik batas transaksi.

### Q5 — Exception FK ramah
`process_rental_v2` menangkap `foreign_key_violation` dan mengganti pesan galat.

Hasil:
CALL lab5.process_rental_v2(1, 999999, 1, 4.99);
→ ERROR: customer, inventory, atau staff tidak dikenal (SQLSTATE 23503)

Informasi yang hilang: nama constraint asli, tabel/kolom yang dilanggar, dan nilai `inventory_id` spesifik yang gagal — sengaja dibuang agar tidak membocorkan detail skema ke pengguna. Penangkapan ini layak karena FK violation punya makna bisnis yang jelas (ID tidak dikenal) dan galat tetap dinaikkan (RAISE), bukan ditelan.

### Q6–Q9 _(diisi Agi)_
...

### Q10–Q15 _(diisi Mael)_
...

### Q16–Q20 _(diisi Azkha)_
...

### Q21–Q24 _(diisi Syifa)_
...

## Refleksi A–E

### Reflektif A
Transaksi dimulai oleh pemanggil (sesi `psql` pada Q3, `with psycopg.connect(...)` pada Q4) — procedure sendiri tidak pernah membuka/menutup transaksi. Transaksi diakhiri otomatis oleh pemanggil juga: pada Q3 lewat rollback otomatis saat `RAISE EXCEPTION` (jumlah baris tidak berubah), pada Q4 lewat penolakan sistem terhadap `COMMIT` eksplisit di dalam procedure (`invalid transaction termination`). Keduanya membuktikan batas transaksi adalah milik pemanggil, bukan procedure.

### Reflektif B _(diisi Agi)_
...

### Reflektif C _(diisi Mael)_
...

### Reflektif D _(diisi Azkha)_
...

### Reflektif E _(diisi Syifa)_
...

## Di Mana Aturan Itu Tinggal
| Aturan | Lapisan | Risiko bila dipindahkan | Bukti |
|---|---|---|---|
| Pembayaran harus positif | Basis data (domain `positive_amount` + validasi di procedure) | Jika dipindah ke aplikasi saja, skrip ad hoc atau tim lain yang menulis langsung ke tabel bisa memasukkan nilai negatif | Q3, Q6 |
| Rental dan pembayaran atomik | Basis data (procedure `process_rental`, satu CALL) | Jika dipisah jadi dua query dari aplikasi, kegagalan di tengah bisa menyisakan data setengah jadi | Q3, Q4 |
| Klien tidak melihat SQL mentah | Lapisan API (terjemahan SQLSTATE → status HTTP) | Jika dihapus, pesan error PostgreSQL bocor ke klien (nama skema, constraint, potongan query) | Q23, Q24 |

## Ringkasan N+1
| Q17 | Q18 | Q19 | Penafsiran |
|---:|---:|---:|---|
| _(diisi Azkha)_ | | | |

## Penggunaan AI dan Verifikasi

### Jelita
Saya pakai AI assistant untuk bantu susun perintah setup, debug masalah teknis di Windows (sampai ketemu data ada di database `pagila`, bukan `latihan`). Selebihnya saya mengikuti instruksi yang bapak berikan di kelas usu.
```
