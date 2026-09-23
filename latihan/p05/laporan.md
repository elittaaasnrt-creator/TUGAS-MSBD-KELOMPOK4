# Laporan Latihan Kelompok Pertemuan 5

## Anggota dan Kontribusi

| Nama                       | NIM       | Kontribusi                                    | Commit |
| -------------------------- | --------- | --------------------------------------------- | ------ |
| Jelita Hati Sinurat        | 251402141 | Setup (q00) + Q1–Q5 + Reflektif A + README.md | ...    |
| M. Dzakwan Ismail Rangkuti | 251402014 | Q10–Q15 + Reflektif C                         | ...    |
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
```

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

### Q10 — Executing Parameterized SELECT
- **Deskripsi**: Menggunakan pemanggilan parameter `%s` agar pengemudian query aman dari injeksi SQL.
- **Hasil Tangkapan**:
  - `(1, 'MARY', 'SMITH')`

### Q11 — Preventing SQL Injection
- **Deskripsi**: Menguji payload `SMITH' OR '1'='1` dengan query berparameter.
- **Hasil**:
  - `Jumlah baris ditemukan: 0` (Terbukti aman karena payload diperlakukan sebagai nilai string harfiah, bukan potongan kode SQL).

### Q12 — Dynamic Identifiers using `sql.Identifier`
- **Deskripsi**: Mengamankan nama kolom dinamis mengutamakan allow-list dan `psycopg.sql.Identifier`.
- **Hasil Query**:
  - `[(375, 'AARON'), (367, 'ADAM'), (525, 'ADRIAN')]`

### Q13 — Application-Side Transaction Rollback
- **Deskripsi**: Membuktikan bahwa exception yang dilemparkan di dalam blok transaksi Python akan secara otomatis memicu `ROLLBACK` oleh driver psycopg.
- **Bukti Eksperimen**:
  - Baris `rental_tx` sebelum exception: `1`
  - Baris `rental_tx` sesudah exception: `1` *(Perubahan dalam transaksi tidak tersimpan/ter-rollback)*.

### Q14 — Managing Connections with ConnectionPool
- **Deskripsi**: Mengelola koneksi database secara efisien menggunakan `ConnectionPool` untuk melayani 5 permintaan berurutan.
- **Statistik Pool**:
  - Total koneksi aktif: `2` (`pool_min=2`, `pool_max=2`)
  - Ditangani oleh Backend PID: `1070` dan `1071` secara bergantian.

### Q15 — Monitoring Idle in Transaction State
- **Deskripsi**: Membuka koneksi transaksi lalu mendiamkannya tanpa `COMMIT`/`ROLLBACK` untuk memicu status `idle in transaction`.
- **Bukti Tangkapan `pg_stat_activity`**:
  ```text
   pid  |        state        |          xact_start           |  query   
  ------+---------------------+-------------------------------+-----------
   1172 | idle in transaction | 2026-09-22 17:54:44.355965+00 | SELECT 1;
  (1 row)
  
### Q16 — Model deklaratif 

Model `Customer` dipetakan ke `public.customer` (tabel Pagila, tidak dibuat ulang) dan `Rental` dipetakan ke `lab5.rental_tx`. Relasi satu-ke-banyak dihubungkan lewat `relationship(back_populates=...)` di kedua sisi. Kode lengkap di `lab5_orm.py`.

### Q17 — Bukti N+1

Mengambil 10 customer lalu mengakses `c.rentals` untuk masing-masing menghasilkan **11 SELECT statement**: 1 SELECT untuk daftar customer, ditambah 10 SELECT terpisah (satu per customer) untuk mengambil rental-nya — sesuai target soal.

```
SELECT ... FROM public.customer LIMIT 10
SELECT ... FROM lab5.rental_tx WHERE customer_id = 1
SELECT ... FROM lab5.rental_tx WHERE customer_id = 2
... (berulang untuk customer_id 3–10)
```

### Q18 — selectinload

Query yang sama dengan `selectinload(Customer.rentals)` menghasilkan **2 SELECT statement**: 1 untuk customer, 1 untuk seluruh rental sekaligus memakai `WHERE customer_id IN (1,2,...,10)`. Sesuai target soal.

```
SELECT ... FROM public.customer LIMIT 10
SELECT ... FROM lab5.rental_tx WHERE customer_id IN (1,2,3,4,5,6,7,8,9,10)
```

### Q19 — joinedload

Dengan `joinedload(Customer.rentals)`, hanya **1 SELECT statement** dijalankan, memakai `LEFT OUTER JOIN` antara `customer` dan `rental_tx`. Dibandingkan Q18: `selectinload` memakai 2 statement terpisah (1 induk + 1 `IN`), sedangkan `joinedload` menyatukan keduanya dalam 1 statement lewat JOIN, tapi baris customer terduplikasi sebanyak jumlah rental-nya sebelum di-deduplikasi lewat `.unique()` di sisi Python.

### Q20 — ORM vs SQL mentah

Query analitik "5 film tersewa terbanyak" ditulis dalam dua versi: ORM (SQLAlchemy expression) dan SQL mentah (`text()`). Hasil keduanya identik:

| Judul Film | Jumlah Sewa |
|---|---:|
| BUCKET BROTHERHOOD | 34 |
| ROCKETEER MOTHER | 33 |
| RIDGEMONT SUBMARINE | 32 |
| SCALAWAG DUCK | 32 |
| FORWARD TEMPLE | 32 |

Waktu eksekusi: **ORM 27,587 ms**, **SQL mentah 5,175 ms** — SQL mentah kurang lebih 5x lebih cepat pada percobaan ini.

## Ringkasan N+1

| Q17 | Q18 | Q19 | Penafsiran |
|---:|---:|---:|---|
| 11 | 2 | 1 | Lazy load default (Q17) memicu satu query tambahan per baris induk. `selectinload` (Q18) memangkas ini jadi satu query batch. `joinedload` (Q19) menyatukan semuanya jadi satu JOIN, tapi menduplikasi baris induk di hasil mentahnya. |

### Q21–Q24 _(diisi Syifa)_
...

## Refleksi A–E

### Reflektif A
Transaksi dimulai oleh pemanggil (sesi `psql` pada Q3, `with psycopg.connect(...)` pada Q4) — procedure sendiri tidak pernah membuka/menutup transaksi. Transaksi diakhiri otomatis oleh pemanggil juga: pada Q3 lewat rollback otomatis saat `RAISE EXCEPTION` (jumlah baris tidak berubah), pada Q4 lewat penolakan sistem terhadap `COMMIT` eksplisit di dalam procedure (`invalid transaction termination`). Keduanya membuktikan batas transaksi adalah milik pemanggil, bukan procedure.

### Reflektif B _(diisi Agi)_
...

### Reflektif C

**Persamaan:**
Baik *rollback* Q3 (yang dipicu oleh validasi basis data via `RAISE EXCEPTION`) maupun Q13 (yang dipicu oleh *exception* Python di dalam blok `with conn.transaction():`) sama-sama menjamin prinsip **Atomisitas (Atomicity)**. Keduanya memastikan bahwa seluruh rangkaian operasi *INSERT* (ke `rental_tx` dan `payment_tx`) harus berhasil sepenuhnya atau dibatalkan total (*all-or-nothing*), sehingga database tidak pernah menyimpan data setengah jadi.

**Satu Hal yang Hanya Dapat Dilakukan Sisi Aplikasi:**
Sisi aplikasi dapat memicu *rollback* berdasarkan **logika bisnis eksternal atau kegagalan sistem di luar lingkungan PostgreSQL**. 

Contohnya, aplikasi Python dapat membatalkan transaksi database jika *API payment gateway* pihak ketiga (seperti Midtrans/Stripe) merespons dengan galat, terjadi kegagalan pengiriman surel konfirmasi, atau syarat verifikasi internal Python tidak terpenuhi—kondisi-kondisi eksternal yang sama sekali tidak dapat dideteksi atau dijangkau oleh prosedur SQL di dalam basis data.

### Reflektif D _(diisi Azkha)_

Untuk Q20, versi SQL mentah dipilih jika kode dibaca ulang tim enam bulan lagi. Query ini murni analitik (agregasi read-only, bukan memuat objek domain yang akan dimodifikasi), dan pada percobaan kami SQL mentah terbukti sekitar 5x lebih cepat (5,175 ms berbanding 27,587 ms untuk ORM). Query analitik seperti ini juga lebih mudah dioptimasi langsung di level database (index, `EXPLAIN`) ketika ditulis sebagai SQL mentah, tanpa lapisan abstraksi tambahan dari ORM.

`joinedload` lebih tepat dari `selectinload` ketika jumlah baris induk sedikit dan relasinya tidak terlalu banyak — misalnya mengambil satu customer beserta rental-nya untuk halaman detail. `joinedload` hanya butuh satu round-trip ke database (terbukti di Q19: 1 statement), sehingga overhead jaringan lebih kecil dibanding `selectinload` yang tetap butuh dua round-trip. Sebaliknya, `selectinload` lebih tepat saat jumlah baris induk banyak (seperti pada Q17–Q18 dengan 10 customer), karena `joinedload` menduplikasi baris induk sebanyak jumlah relasinya, menambah beban transfer data dan butuh deduplikasi manual lewat `.unique()` di sisi aplikasi.

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

### M. Dzakwan Ismail Rangkuti
Saya menggunakan AI assistant untuk membantu memahami penanganan transaksi aplikasi pada driver Python (`psycopg 3`), menyusun skrip pengujian `ConnectionPool`, serta menganalisis kondisi `idle in transaction` dan penanganan *rollback* transaksi di sisi aplikasi Python untuk Q10–Q15 dan Reflektif C.