# Laporan Latihan Kelompok Pertemuan 5

## Anggota dan Kontribusi

| Nama                       | NIM       | Kontribusi                                             | Commit                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| -------------------------- | --------- | ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Jelita Hati Sinurat        | 251402141 | Setup (q00) + Q1–Q5 + Reflektif A + README.md          | [9e85a12](https://github.com/elittaaasnrt-creator/TUGAS-MSBD-KELOMPOK4/commit/9e85a12), [6934541](https://github.com/elittaaasnrt-creator/TUGAS-MSBD-KELOMPOK4/commit/6934541)                                                                                                                                                                                                                                                                         |
| M. Dzakwan Ismail Rangkuti | 251402014 | Q10–Q15 + Reflektif C                                  | [6b11f17](https://github.com/elittaaasnrt-creator/TUGAS-MSBD-KELOMPOK4/commit/6b11f17), [6a8a32c](https://github.com/elittaaasnrt-creator/TUGAS-MSBD-KELOMPOK4/commit/6a8a32c)                                                                                                                                                                                                                                                                         |
| Agi Aginta Sembiring       | 251402059 | Q6–Q9 + Reflektif B                                    | [aa0a150](https://github.com/elittaaasnrt-creator/TUGAS-MSBD-KELOMPOK4/commit/aa0a150)                                                                                                                                                                                                                                                                                                                                                                 |
| M. Azkha Amorie            | 251402092 | Q16–Q20 + Reflektif D + seed data + rapikan laporan.md | [20738ee](https://github.com/elittaaasnrt-creator/TUGAS-MSBD-KELOMPOK4/commit/20738ee), [ea32193](https://github.com/elittaaasnrt-creator/TUGAS-MSBD-KELOMPOK4/commit/ea32193), [7c063da](https://github.com/elittaaasnrt-creator/TUGAS-MSBD-KELOMPOK4/commit/7c063da), [e9542fb](https://github.com/elittaaasnrt-creator/TUGAS-MSBD-KELOMPOK4/commit/e9542fb), [40e747c](https://github.com/elittaaasnrt-creator/TUGAS-MSBD-KELOMPOK4/commit/40e747c) |
| Syifa Nazira               | 251402126 | Q21–Q24 + Reflektif E                                  | [81e8f30](https://github.com/elittaaasnrt-creator/TUGAS-MSBD-KELOMPOK4/commit/81e8f30)                                                                                                                                                                                                                                                                                                                                                                 |

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

```sql
CALL lab5.process_rental(1, 1, 1, 4.99);
```

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

### Q6–Q9

**Q6 — Domain `positive_amount`**

Percobaan 1: Nilai nol

```sql
INSERT INTO lab5.payment_tx (payment_id, amount)
VALUES (9991, 0);
```

ERROR: value for domain positive_amount violates check constraint "positive_amount_check"
SQLSTATE: 23514

Percobaan 2: Nilai negatif

```sql
INSERT INTO lab5.payment_tx (payment_id, amount)
VALUES (9992, -1000);
```

ERROR: value for domain positive_amount violates check constraint "positive_amount_check"
SQLSTATE: 23514

**Q7 — Enum `rental_status`**

Percobaan 1 (sebelum `ALTER TYPE`):

```sql
UPDATE lab5.rental_tx SET status = 'EXPIRED' WHERE rental_id = 1;
```

ERROR: invalid input value for enum rental_status: "EXPIRED"
SQLSTATE: 22P02

Menambahkan nilai baru:

```sql
ALTER TYPE lab5.rental_status ADD VALUE 'EXPIRED';
```

ALTER TYPE

Percobaan 2 (setelah `ALTER TYPE`):

```sql
UPDATE lab5.rental_tx SET status = 'EXPIRED' WHERE rental_id = 1;
```

UPDATE 1

**Q8 — Array `tags`**

```sql
UPDATE lab5.rental_tx SET tags = ARRAY['promo','akhir-pekan','anggota'] WHERE rental_id = 1;
SELECT rental_id, tags FROM lab5.rental_tx WHERE 'promo' = ANY(tags);
```

rental_id | tags
-----------+-----------------------------
1 | {promo,akhir-pekan,anggota}
(1 row)

Operator `ANY(tags)` berhasil menemukan baris yang memiliki tag `'promo'` di dalam array.

**Q9 — JSONB `metadata`**

```sql
UPDATE lab5.rental_tx SET metadata = '{"channel":"web","device":"android"}'::jsonb WHERE rental_id = 1;
SELECT rental_id, metadata ->> 'channel' AS kanal FROM lab5.rental_tx WHERE rental_id = 1;
```

rental_id | kanal
-----------+-------
1 | web
(1 row)

Operator `->>` mengambil nilai `channel` dari JSONB sebagai teks biasa.

### Q10 — Executing Parameterized SELECT

- **Deskripsi**: Menggunakan pemanggilan parameter `%s` agar pengemudian query aman dari injeksi SQL.
- **Hasil Tangkapan**:
  - `(1, 'MARY', 'SMITH')`

### Q11 — Preventing SQL Injection

- **Deskripsi**: Mencetak SQL hasil f-string dengan payload `SMITH' OR '1'='1` tanpa menjalankannya, lalu menguji versi berparameter dengan payload yang sama.
- **SQL hasil f-string (tidak dijalankan)**:
  SELECT \* FROM public.customer WHERE last_name = 'SMITH' OR '1'='1'
- **Hasil query berparameter (payload sama)**:
  []
  Jumlah baris: 0
  Terbukti aman karena PostgreSQL memperlakukan seluruh payload sebagai satu nilai string literal untuk dicocokkan ke `last_name`, bukan sebagai bagian dari struktur SQL — bandingkan dengan versi f-string yang membuat kondisi `'1'='1'` selalu bernilai TRUE.

### Q12 — Dynamic Identifiers using `sql.Identifier`

- **Deskripsi**: Mengamankan nama kolom dinamis mengutamakan allow-list dan `psycopg.sql.Identifier`.
- **Hasil Query**:
  - `[(375, 'AARON'), (367, 'ADAM'), (525, 'ADRIAN')]`

### Q13 — Application-Side Transaction Rollback

- **Deskripsi**: Membuktikan bahwa exception yang dilemparkan di dalam blok transaksi Python akan secara otomatis memicu `ROLLBACK` oleh driver psycopg.
- **Bukti Eksperimen**:
  - Baris `rental_tx` sebelum exception: `1`
  - Baris `rental_tx` sesudah exception: `1` _(Perubahan dalam transaksi tidak tersimpan/ter-rollback)_.

### Q14 — Managing Connections with ConnectionPool

- **Deskripsi**: Mengelola koneksi database secara efisien menggunakan `ConnectionPool` untuk melayani 5 permintaan berurutan.
- **Statistik Pool**:
  - Total koneksi aktif: `2` (`pool_min=2`, `pool_max=2`)
  - Ditangani oleh Backend PID: `1070` dan `1071` secara bergantian.

### Q15 — Monitoring Idle in Transaction State

- **Deskripsi**: Membuka koneksi transaksi lalu mendiamkannya tanpa `COMMIT`/`ROLLBACK` untuk memicu status `idle in transaction`.
- **Bukti Tangkapan `pg_stat_activity`**:
  pid | state | xact_start | query
  ------+----------------------+-------------------------------+-----------
  1172 | idle in transaction | 2026-09-22 17:54:44.355965+00 | SELECT 1;
  (1 row)

### Q16 — Model deklaratif

Model `Customer` dipetakan ke `public.customer` (tabel Pagila, tidak dibuat ulang) dan `Rental` dipetakan ke `lab5.rental_tx`. Relasi satu-ke-banyak dihubungkan lewat `relationship(back_populates=...)` di kedua sisi. Kode lengkap di `lab5_orm.py`.

### Q17 — Bukti N+1

Mengambil 10 customer lalu mengakses `c.rentals` untuk masing-masing menghasilkan **11 SELECT statement**: 1 SELECT untuk daftar customer, ditambah 10 SELECT terpisah (satu per customer) untuk mengambil rental-nya — sesuai target soal.

SELECT ... FROM public.customer LIMIT 10
SELECT ... FROM lab5.rental_tx WHERE customer_id = 1
SELECT ... FROM lab5.rental_tx WHERE customer_id = 2
... (berulang untuk customer_id 3–10)

### Q18 — selectinload

Query yang sama dengan `selectinload(Customer.rentals)` menghasilkan **2 SELECT statement**: 1 untuk customer, 1 untuk seluruh rental sekaligus memakai `WHERE customer_id IN (1,2,...,10)`. Sesuai target soal.

SELECT ... FROM public.customer LIMIT 10
SELECT ... FROM lab5.rental_tx WHERE customer_id IN (1,2,3,4,5,6,7,8,9,10)

### Q19 — joinedload

Dengan `joinedload(Customer.rentals)`, hanya **1 SELECT statement** dijalankan, memakai `LEFT OUTER JOIN` antara `customer` dan `rental_tx`. Dibandingkan Q18: `selectinload` memakai 2 statement terpisah (1 induk + 1 `IN`), sedangkan `joinedload` menyatukan keduanya dalam 1 statement lewat JOIN, tapi baris customer terduplikasi sebanyak jumlah rental-nya sebelum di-deduplikasi lewat `.unique()` di sisi Python.

### Q20 — ORM vs SQL mentah

Query analitik "5 film tersewa terbanyak" ditulis dalam dua versi: ORM (SQLAlchemy expression) dan SQL mentah (`text()`). Hasil keduanya identik:

| Judul Film          | Jumlah Sewa |
| ------------------- | ----------: |
| BUCKET BROTHERHOOD  |          34 |
| ROCKETEER MOTHER    |          33 |
| RIDGEMONT SUBMARINE |          32 |
| SCALAWAG DUCK       |          32 |
| FORWARD TEMPLE      |          32 |

Waktu eksekusi: **ORM 27,587 ms**, **SQL mentah 5,175 ms** — SQL mentah kurang lebih 5x lebih cepat pada percobaan ini.

### Q21 — Dependency koneksi (`get_conn`)

- **Deskripsi**: Membuat fungsi dependency FastAPI `get_conn` dengan gaya `with yield` untuk meminjam koneksi dari `ConnectionPool` secara terisolasi per permintaan HTTP.
- **Potongan Kode**:

```python
def get_conn():
    with pool.connection() as conn:
        yield conn
```

### Q22 — POST /rentals

- **Deskripsi**: Membuat endpoint FastAPI `POST /rentals` yang memanggil _procedure_ `lab5.process_rental` di basis data dan mengembalikan status `201 Created` beserta `rental_id`.
- **Perintah curl**:

```bash
curl -s -X POST localhost:8000/rentals -H 'content-type: application/json' \
  -d '{"customer_id":1,"inventory_id":1,"staff_id":1,"amount":4.99}'
```

- **Respons (HTTP 201 Created)**:

```json
{ "rental_id": 1, "message": "Rental berhasil diproses" }
```

### Q23 — Handling Nilai Negatif (Input Validation)

- **Deskripsi**: Menguji pengiriman nilai `amount` negatif (-4.99) ke endpoint. Validasi Pydantic di FastAPI secara otomatis mencegat input invalid dan mengembalikan status `422 Unprocessable Entity` tanpa membiarkan query menyentuh atau mengekspos error SQL basis data.
- **Perintah curl**:

```bash
curl -s -i -X POST localhost:8000/rentals -H 'content-type: application/json' \
  -d '{"customer_id":1,"inventory_id":1,"staff_id":1,"amount":-4.99}'
```

- **Respons (HTTP 422 Unprocessable Entity)**:

```json
{
  "detail": [
    {
      "type": "greater_than",
      "loc": ["body", "amount"],
      "msg": "Input should be greater than 0",
      "input": -4.99,
      "ctx": { "gt": 0.0 }
    }
  ]
}
```

### Q24 — Inventory Tidak Ada (Database FK Exception Mapping)

- **Deskripsi**: Menguji pengiriman `inventory_id` yang tidak terdaftar di database (misal `99999`). Handler menangkap `psycopg.errors.ForeignKeyViolation` dan menerjemahkannya menjadi status `409 Conflict` dengan pesan yang ramah tanpa membocorkan detail skema internal.
- **Perintah curl**:

```bash
curl -s -i -X POST localhost:8000/rentals -H 'content-type: application/json' \
  -d '{"customer_id":1,"inventory_id":99999,"staff_id":1,"amount":4.99}'
```

- **Respons Utuh (HTTP 409 Conflict)**:

```json
{
  "detail": "Referensi data tidak ditemukan (Foreign Key Violation)."
}
```

## Refleksi A–E

### Reflektif A

Transaksi dimulai oleh pemanggil (sesi `psql` pada Q3, `with psycopg.connect(...)` pada Q4) — procedure sendiri tidak pernah membuka/menutup transaksi. Transaksi diakhiri otomatis oleh pemanggil juga: pada Q3 lewat rollback otomatis saat `RAISE EXCEPTION` (jumlah baris tidak berubah), pada Q4 lewat penolakan sistem terhadap `COMMIT` eksplisit di dalam procedure (`invalid transaction termination`). Keduanya membuktikan batas transaksi adalah milik pemanggil, bukan procedure.

### Reflektif B

**Pertanyaan**: Pilih tags atau metadata. Apakah sebaiknya tetap di sana atau dipindahkan menjadi tabel? Berikan satu pertanyaan bisnis yang dapat mengubah keputusan tersebut.

**Jawaban**: Saya memilih tags.

Menurut saya, tags sebaiknya tetap disimpan sebagai array apabila hanya digunakan untuk menyimpan beberapa label sederhana pada setiap transaksi rental. Penggunaan array lebih praktis karena tidak memerlukan tabel tambahan untuk menyimpan tag.

Namun, apabila tag perlu dikelola secara terpisah, memiliki atribut tambahan, atau sering digunakan dalam analisis bisnis, maka tags lebih baik dipindahkan ke tabel tersendiri.

Pertanyaan bisnis yang dapat mengubah keputusan: Apakah setiap tag perlu memiliki informasi tambahan seperti kategori, deskripsi, dan jumlah penggunaannya untuk keperluan analisis bisnis? Jika jawabannya ya, penggunaan tabel terpisah akan lebih sesuai karena data tag dapat dikelola secara terstruktur dan dikembangkan dengan lebih mudah.

### Reflektif C

**Persamaan:**
Baik _rollback_ Q3 (yang dipicu oleh validasi basis data via `RAISE EXCEPTION`) maupun Q13 (yang dipicu oleh _exception_ Python di dalam blok `with conn.transaction():`) sama-sama menjamin prinsip **Atomisitas (Atomicity)**. Keduanya memastikan bahwa seluruh rangkaian operasi _INSERT_ (ke `rental_tx` dan `payment_tx`) harus berhasil sepenuhnya atau dibatalkan total (_all-or-nothing_), sehingga database tidak pernah menyimpan data setengah jadi.

**Satu Hal yang Hanya Dapat Dilakukan Sisi Aplikasi:**
Sisi aplikasi dapat memicu _rollback_ berdasarkan **logika bisnis eksternal atau kegagalan sistem di luar lingkungan PostgreSQL**. Contohnya, aplikasi Python dapat membatalkan transaksi database jika _API payment gateway_ pihak ketiga (seperti Midtrans/Stripe) merespons dengan galat, terjadi kegagalan pengiriman surel konfirmasi, atau syarat verifikasi internal Python tidak terpenuhi — kondisi-kondisi eksternal yang sama sekali tidak dapat dideteksi atau dijangkau oleh prosedur SQL di dalam basis data.

### Reflektif D

Untuk Q20, versi SQL mentah dipilih jika kode dibaca ulang tim enam bulan lagi. Query ini murni analitik (agregasi read-only, bukan memuat objek domain yang akan dimodifikasi), dan pada percobaan kami SQL mentah terbukti sekitar 5x lebih cepat (5,175 ms berbanding 27,587 ms untuk ORM). Query analitik seperti ini juga lebih mudah dioptimasi langsung di level database (index, `EXPLAIN`) ketika ditulis sebagai SQL mentah, tanpa lapisan abstraksi tambahan dari ORM.

`joinedload` lebih tepat dari `selectinload` ketika jumlah baris induk sedikit dan relasinya tidak terlalu banyak — misalnya mengambil satu customer beserta rental-nya untuk halaman detail. `joinedload` hanya butuh satu round-trip ke database (terbukti di Q19: 1 statement), sehingga overhead jaringan lebih kecil dibanding `selectinload` yang tetap butuh dua round-trip. Sebaliknya, `selectinload` lebih tepat saat jumlah baris induk banyak (seperti pada Q17–Q18 dengan 10 customer), karena `joinedload` menduplikasi baris induk sebanyak jumlah relasinya, menambah beban transfer data dan butuh deduplikasi manual lewat `.unique()` di sisi aplikasi.

### Reflektif E

1. **Pemilihan Abstraksi Koneksi (Q21)**: Menggunakan `ConnectionPool` yang dikelola via context manager `lifespan` pada FastAPI. Peminjaman koneksi menggunakan `yield` memastikan bahwa koneksi hanya dipakai selama siklus permintaan (request-response) berlangsung dan dipastikan langsung kembali ke _pool_ (walaupun terjadi _exception_ di tengah proses execution).

2. **Stored Procedure vs Query Langsung (Q22)**: Memanggil _stored procedure_ `lab5.process_rental` melalui _parameterized query_ (`%s`) membungkus logika bisnis transaksi (pembuatan rental sekaligus pembayaran) secara atomik di sisi basis data. Hal ini mencegah _partial write_ jika aplikasi atau jaringan terputus di tengah proses.

3. **Penanganan Validasi Input (Q23)**: Memanfaatkan tipe data `PositiveFloat` pada skema Pydantic. Validasi dilakukan di layer aplikasi (_boundary_) sebelum koneksi ke basis data dibuat. Ini menghemat penggunaan resource database dan memastikan bahwa query ber-SQLSTATE error tidak perlu dieksekusi untuk input yang secara bentuk sudah salah.

4. **Pemetaan Error Database ke HTTP Status Code (Q24)**: Dengan menangkap `psycopg.errors.ForeignKeyViolation` secara eksplisit dan mengembalikannya sebagai respons HTTP `409 Conflict`, API terlindungi dari kebocoran informasi struktur tabel/constraint internal (_information disclosure_) sekaligus memberikan umpan balik yang informatif bagi klien.

## Di Mana Aturan Itu Tinggal

| Aturan                         | Lapisan                                                       | Risiko bila dipindahkan                                                                                                 | Bukti    |
| ------------------------------ | ------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- | -------- |
| Pembayaran harus positif       | Basis data (domain `positive_amount` + validasi di procedure) | Jika dipindah ke aplikasi saja, skrip ad hoc atau tim lain yang menulis langsung ke tabel bisa memasukkan nilai negatif | Q3, Q6   |
| Rental dan pembayaran atomik   | Basis data (procedure `process_rental`, satu CALL)            | Jika dipisah jadi dua query dari aplikasi, kegagalan di tengah bisa menyisakan data setengah jadi                       | Q3, Q4   |
| Klien tidak melihat SQL mentah | Lapisan API (terjemahan SQLSTATE → status HTTP)               | Jika dihapus, pesan error PostgreSQL bocor ke klien (nama skema, constraint, potongan query)                            | Q23, Q24 |

## Ringkasan N+1

| Q17 | Q18 | Q19 | Penafsiran                                                                                                                                                                                                                             |
| --: | --: | --: | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|  11 |   2 |   1 | Lazy load default (Q17) memicu satu query tambahan per baris induk. `selectinload` (Q18) memangkas ini jadi satu query batch. `joinedload` (Q19) menyatukan semuanya jadi satu JOIN, tapi menduplikasi baris induk di hasil mentahnya. |

## Penggunaan AI dan Verifikasi

### Jelita Hati Sinurat

Saya pakai AI assistant untuk bantu susun perintah setup, debug masalah teknis di Windows (sampai ketemu data ada di database pagila, bukan latihan). Selebihnya saya mengikuti instruksi yang bapak berikan di kelas usu.

### M. Dzakwan Ismail Rangkuti

Saya menggunakan AI assistant untuk membantu memahami penanganan transaksi aplikasi pada driver Python (`psycopg 3`), menyusun skrip pengujian `ConnectionPool`, serta menganalisis kondisi `idle in transaction` dan penanganan _rollback_ transaksi di sisi aplikasi Python untuk Q10–Q15 dan Reflektif C.

### Agi Aginta Sembiring

Saya menggunakan AI assistant untuk membantu saya memahami alur pengerjaan saya serta membantu dalam mengerjakan beberapa hal yang error.

### Muhammad Azkha Amorie

Saya menggunakan AI assistant untuk membantu menyusun model deklaratif SQLAlchemy 2.0 (`Customer`, `Rental`) dan memverifikasi jumlah statement SQL yang dihasilkan lewat `echo=True` untuk Q17–Q19 (N+1, `selectinload`, `joinedload`), termasuk menyusun query analitik pembanding ORM vs SQL mentah untuk Q20 dan Reflektif D.

### Syifa Nazira

Saya menggunakan AI assistant untuk membantu analisis penanganan dependensi koneksi FastAPI (`psycopg_pool`), pemetaan error `psycopg.errors.ForeignKeyViolation` ke status HTTP 409, penyusunan perintah pengujian `curl` untuk Q21–Q24, serta merumuskan poin refleksi pemisahan tanggung jawab layer API dan basis data (Reflektif E).

## Tautan Merge Request

<!-- isi setelah semua bagian lengkap dan MR dibuka -->

[Merge Request Pertemuan 5](URL_MR_DI_SINI)
