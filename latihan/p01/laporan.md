# Laporan Latihan Mandiri — Pertemuan 1

## Menyiapkan Lingkungan Kerja Basis Data

**Kelompok:** TUGAS-MSBD-KELOMPOK 4

**Anggota:**

- Jelita Hati Sinurat - 251402141 (elittaaasnrt-creator) — Project Manager
- M. Dzakwan Rangkuti - 251402014 (dzakwanrangkuti)
- Agi Aginta Sembiring - 251402059 (agisembiring263-pixel)
- M. Azkha Amorie - 251402092 (azkhaamorie)
- Syifa Nazira - 251402126 (ziraa94)

---

### Keluaran `docker --version`

```
Docker version 29.7.2, build a7dcaa6
```

Bukti: `bukti/docker --version.png`

---

### Keluaran `docker compose version`

```
Docker Compose version v5.3.1
```

Bukti: `bukti/docker compose version.png`

---

### Keluaran `docker compose ps`

```
NAME         IMAGE            COMMAND                  SERVICE    CREATED         STATUS                   PORTS
msbd-mongo   mongo:8          "docker-entrypoint.s…"   mongo      7 minutes ago   Up 7 minutes             0.0.0.0:27017->27017/tcp
msbd-pg      postgres:17      "docker-entrypoint.s…"   postgres   7 minutes ago   Up 7 minutes (healthy)   0.0.0.0:5432->5432/tcp
msbd-redis   redis:7-alpine   "docker-entrypoint.s…"   redis      7 minutes ago   Up 7 minutes             0.0.0.0:6379->6379/tcp
```

Ketiga container jalan normal, postgres-nya status healthy.

Bukti: `bukti/docker compose ps.png`

Catatan tambahan: pas cek `docker compose logs postgres`, sempat kaget lihat banyak baris `FATAL: database "msbd" does not exist` yang berulang terus. Ternyata itu dari healthcheck (`pg_isready -U msbd`) yang defaultnya nyoba connect ke database bernama sama kayak user (`msbd`), padahal database yang dibuat namanya `latihan`. Jadi bukan error, cuma healthcheck-nya aja yang gak nyebutin nama db spesifik. Buktinya status container tetap healthy.

---

### Keluaran `SELECT version();`

```
PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
```

Bukti: `bukti/langkah3-select-version.png`

---

### Jawaban tiga pertanyaan tentang Image, Container, dan Volume

**Apa itu Docker Image?**

> berkas mentah yang isinya semua bahan dan instruksi, mulai dari kode program, sistem operasi dasar, sampai library yang dibutuhkan, supaya aplikasi bisa berjalan. Tetapi image docker ini belum jalan, baru sebatas rancangan nya saja.

**Apa itu Container?**

> nah, kalo image tadi itu sebagai cetakan, container sebagai wujud nyata nya saat di jalankan

**Apa fungsi Volume?**

> fungsi volume adalah sebagai tempat penyimpanan permanen. sifat dasar nya cointaner itu kan sementara, jadi kalo cointaner nya di hapus semua data di dalam nya bakal ikut hilang. nah, volume ini bertugas menyimpan data penting seperti database atau file upload, jadi datanya tetap aman walaupun cointaner nya di hancurkan.

---

### Jawaban empat pertanyaan pada Langkah 2

**1. Apa yang terjadi jika bagian `volumes:` pada layanan PostgreSQL dihapus, lalu container dihentikan dengan `docker compose down -v`?**

> semua data di dalam database PostgreSQL akan hilang permanen. soalnya tanpa volume, database cuma nyimpan data di dalam container yang sifatnya itu sementara. 

**2. Mengapa pemetaan port ditulis "5432:5432" dan bukan cukup satu angka? Apa yang harus diubah apabila komputer sudah memiliki PostgreSQL lain yang menggunakan port 5432?**

> jadi format dua angka itu maksudnya "Port laptop: Port container". jadi kalo di laptop udah ada PostgreSQl lain yang make port 5432, tinggal ubah angka yang sebelah kiri aja (misal jadi "5433:5432"). jadi port laptopnya pakai 5433, tapi tetep nembak ke port 5432 milik container.

**3. Apa fungsi blok `healthcheck`? Mengapa healthcheck penting ketika ada layanan lain yang bergantung pada basis data?**

> healthcheck itu ibarat fitur cek status kesehatan otomatis, dia tugasnya nanya ke PostgreSQL "apakah udah siap dipake atau belum?" ini penting agar aplikasi backend tersebut bisa nungguin PostgreSQL bener-bener ready dulu sebelum mencoba connect. kalo nggak pakai ini, aplikasi backend bisa langsung crash gara-gara maksa nyambung pas PostgreSQL-nya baru proses nyala.

**4. Menyimpan password langsung di `docker-compose.yml` merupakan praktik yang kurang baik. Sebutkan satu cara yang lebih aman dan jelaskan mengapa penting ketika berkas masuk ke repositori Git.**

> Caranya adalah dengan memindahkan password ke dalam file .env tersendiri, misalkan kita buat variabel POSTGRES_PASSWORD=${DB_PASS}, terus masukkan nama file .env tersebut ke dalam .gitignore.

---

### Perbandingan penggunaan psql dan DBeaver

Sebelum masuk perbandingan, ini eksplorasi yang dilakukan lewat psql di database `latihan`:

```
\l   -> ada 4 database: latihan, postgres, template0, template1
\dt  -> Did not find any relations (belum ada tabel, karena Pagila belum di-restore)
\dn  -> 1 schema: public (owner: pg_database_owner)
\du  -> 1 role: msbd (Superuser, Create role, Create DB, Replication, Bypass RLS)

SHOW data_directory;  -> /var/lib/postgresql/data
SHOW shared_buffers;  -> 128MB
\timing on            -> Timing is on.
```

Bukti: `bukti/langkah3-list-database.png`, `bukti/langkah3-dt-dn-du.png`, `bukti/SHOW data_directory, SHOW shared_buffers, timing on.png`

Koneksi DBeaver ke database `latihan` juga berhasil (host localhost, port 5432, user msbd). ER Diagram di schema `public` masih nunjukin "0 objects" karena waktu itu Pagila belum di-restore.
Bukti: `bukti/langkah3-dbeaver-new-connection.png`, `bukti/langkah3-dbeaver-connected.png`, `bukti/langkah3-dbeaver-er-diagram.png`

**Lebih cepat pakai psql:**

> cek status cepat atau eksekusi query singkat, contohnya pas mau ngelakuin pengecekan ringan kayak SELECT version();, ngeliat daftar database (\l), atau sekadar mau tau direktori penyimpanan (SHOW data_directory;). pake psql itu jauh lebih cepet karena tinggal ketik satu baris perintah di terminal tanpa perlu nungguin aplikasi berat kebuka dulu.

**Lebih cepat pakai DBeaver:**

> melihat struktur tabel dan visualisasi ER Diagram. kalo mau paham hubungan antar-tabel (relasi foreign key), ngebuka ER Diagram di DBeaver tinggal sekali klik dan langsung kelihatan petanya secara visual. kalo harus ngebayangin skema database yang kompleks cuma dari teks di terminal, bakalan makan waktu lebih lama.

---

### Hasil query V1

Sebelum V1, restore Pagila dilakukan dengan `createdb -U msbd pagila` lalu `pg_restore -U msbd -d pagila --no-owner /dump/pagila.dump`. Dua-duanya jalan lancar tanpa error. Setelah dicek `\dt`, ketemu 21 tabel — sama dengan nilai rujukan di modul.
Bukti restore: `bukti/langkah4-restore-pagila.png`

```sql
SELECT count(*)
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE';
```

```
 count
-------
    21
(1 row)
```

Bukti: `bukti/langkah4-v1-jumlah-tabel.png`

---

### Hasil query V2

```sql
SELECT relname,
       pg_size_pretty(pg_total_relation_size(relid)) AS ukuran
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 10;
```

```
     relname      | ukuran
------------------+---------
 rental           | 2352 kB
 film             | 952 kB
 payment_p2017_04 | 656 kB
 payment_p2017_03 | 568 kB
 film_actor       | 488 kB
 inventory        | 440 kB
 payment_p2017_02 | 296 kB
 payment_p2017_01 | 248 kB
 customer         | 216 kB
 address          | 160 kB
(10 rows)
```

Bukti: `bukti/langkah4-v2-tabel-terbesar.png`

---

### Hasil query V3

```sql
SELECT f.title, count(*) AS total_sewa
FROM rental r
JOIN inventory i
  ON i.inventory_id = r.inventory_id
JOIN film f
  ON f.film_id = i.film_id
GROUP BY f.title
ORDER BY total_sewa DESC
LIMIT 5;
```

```
        title        | total_sewa
---------------------+------------
 BUCKET BROTHERHOOD  |         34
 ROCKETEER MOTHER    |         33
 RIDGEMONT SUBMARINE |         32
 SCALAWAG DUCK       |         32
 FORWARD TEMPLE      |         32
(5 rows)
```

Bukti: `bukti/langkah4-v3-film-terbanyak.png`

---

### Hasil V4 — `EXPLAIN ANALYZE`

```sql
EXPLAIN ANALYZE
SELECT f.title, count(*)
FROM rental r
JOIN inventory i
  ON i.inventory_id = r.inventory_id
JOIN film f
  ON f.film_id = i.film_id
GROUP BY f.title;
```

```
HashAggregate  (cost=713.69..723.69 rows=1000 width=23) (actual time=15.370..15.521 rows=958 loops=1)
  Group Key: f.title
  Batches: 1  Memory Usage: 193kB
  ->  Hash Join  (cost=238.57..633.47 rows=16044 width=15) (actual time=1.823..11.001 rows=16044 loops=1)
        Hash Cond: (i.film_id = f.film_id)
        ->  Hash Join  (cost=128.07..480.67 rows=16044 width=2) (actual time=1.202..6.922 rows=16044 loops=1)
              Hash Cond: (r.inventory_id = i.inventory_id)
              ->  Seq Scan on rental r  (cost=0.00..310.44 rows=16044 width=4) (actual time=0.009..1.605 rows=16044 loops=1)
              ->  Hash  (cost=70.81..70.81 rows=4581 width=6) (actual time=1.166..1.174 rows=4581 loops=1)
                    Buckets: 8192  Batches: 1  Memory Usage: 234kB
                    ->  Seq Scan on inventory i  (cost=0.00..70.81 rows=4581 width=6) (actual time=0.006..0.452 rows=4581 loops=1)
        ->  Hash  (cost=98.00..98.00 rows=1000 width=19) (actual time=0.613..0.618 rows=1000 loops=1)
              Buckets: 1024  Batches: 1  Memory Usage: 60kB
              ->  Seq Scan on film f  (cost=0.00..98.00 rows=1000 width=19) (actual time=0.142..0.415 rows=1000 loops=1)
Planning Time: 0.403 ms
Execution Time: 15.668 ms
(16 rows)
```

Bukti: `bukti/langkah4-v4-explain-analyze.png`

---

### Kalimat: "Yang paling membingungkan dari keluaran ini adalah ..."

> "Yang paling membingungkan dari keluaran ini adalah banyaknya istilah-istilah teknis PostgreSQL,angka-angka perkiraan cost, serta peletakan teks nya atau tampilan kode nya yang berantakan."

---

### Tautan repositori Git tim

https://github.com/elittaaasnrt-creator/TUGAS-MSBD-KELOMPOK4

Proses setup dan push ke GitHub sempat ada kendala kecil (folder ke-nested waktu salah satu anggota clone, sudah dirapikan lagi). Bukti proses: `bukti/langkah5-git-status.png`, `bukti/langkah5-git-merge-vim.png`, `bukti/langkah5-repo-setelah-merge.png`

---

### Daftar commit masing-masing anggota

| Anggota              | Commit                                                                                                                                                                                                         |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Jelita Hati Sinurat  | chore: menyiapkan lingkungan MSBD; fix: merapikan struktur repo dan menambahkan folder latihan/p01; docs: menambahkan bukti screenshot langkah 1-5; docs: melengkapi laporan dengan referensi bukti screenshot; feat: menambahkan eksperimen index pada tantangan tambahan |
| M. Dzakwan Rangkuti  | chore: menjalankan dan memverifikasi environment docker compose                                                                                                                                                |
| Agi Aginta Sembiring | feat: menambahkan file verifikasi.sql untuk query langkah 4                                                                                                                                                                                     |
| M. Azkha Amorie      | docs: menambahkan perintah.md untuk dokumentasi langkah kerja                                                                                                                                                                                     |
| Syifa Nazira         | docs: menyusun dan melengkapi seluruh draft laporan.md akhir                                                                                                                                                                                                     |

---

### 🚀 Tantangan Tambahan — Index dan Optimasi Query

Dikerjakan oleh: Jelita Hati Sinurat

Sebagai eksperimen tambahan, dibuat tabel `besar` berisi 2 juta baris data acak, lalu dibandingkan waktu pencarian sebelum dan sesudah kolom `nilai` diberi index.

```sql
CREATE TABLE besar AS
SELECT g AS id,
       md5(g::text) AS nilai
FROM generate_series(1, 2000000) g;
```
Waktu pembuatan tabel: **9160.763 ms (±9,16 detik)**

Pencarian satu baris spesifik dicoba pakai nilai `c4ca4238a0b923820dcc509a6f75849b` (id = 1):

```sql
SELECT * FROM besar WHERE nilai = 'c4ca4238a0b923820dcc509a6f75849b';
```

**Sebelum ada index:** waktu pencarian **198.061 ms**. PostgreSQL harus scan seluruh 2 juta baris satu per satu (sequential scan) karena belum ada struktur yang bisa dipakai buat langsung nemuin lokasi data.

Setelah itu dibuat index pada kolom `nilai`:
```sql
CREATE INDEX ON besar(nilai);
```
Waktu pembuatan index: **8750.863 ms (±8,75 detik)**

**Setelah ada index:** query pencarian yang sama dijalankan ulang, waktunya turun jadi **3.555 ms**.

| Kondisi | Waktu |
|---|---|
| Sebelum index | 198.061 ms |
| Sesudah index | 3.555 ms |
| Percepatan | ±56x lebih cepat |

**Kesimpulan:** index bikin PostgreSQL nggak perlu lagi meriksa semua baris satu-satu buat nemuin data yang dicari — mirip kayak daftar isi di buku, tinggal loncat langsung ke lokasi yang tepat. Tapi index juga bukan gratis: butuh waktu ±8,75 detik buat dibuat di awal (untuk 2 juta baris), dan tiap kali ada data baru masuk, index itu juga perlu diperbarui, yang berarti proses insert/update jadi sedikit lebih lambat dibanding tabel tanpa index.

Bukti: `bukti/tantangan-index-besar.png`
