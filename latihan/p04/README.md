# Latihan Pertemuan 4 — SQL Lanjutan II

Audit Log, Materialized View, dan Migrasi Aman. Dikerjakan di skema `lab4` pada database Pagila (PostgreSQL 17), supaya data asli di skema `public` tidak ikut berubah.

## Prasyarat

- Docker & Docker Compose sudah jalan, container `postgres` aktif (cek dengan `docker compose ps`)
- Database `pagila` sudah ada di dalam container
- Ekstensi `btree_gist` (dibutuhkan untuk Q17, constraint EXCLUDE) — dipasang lewat `CREATE EXTENSION IF NOT EXISTS btree_gist;`, sudah termasuk di berkas soalnya masing-masing
- Untuk Q8 dan Q20, siapkan **dua sesi psql/terminal terpisah** yang jalan bersamaan (lihat bagian "Dua Sesi" di bawah)

## Cara Menjalankan

Semua berkas `.sql` dijalankan dengan pola yang sama: copy ke dalam container, lalu eksekusi lewat psql.

docker compose cp latihan/p04/<nama_file>.sql postgres:/tmp/<nama_file>.sql
docker compose exec postgres psql -U msbd -d pagila -f /tmp/<nama_file>.sql


**Jalankan `q00_setup.sql` terlebih dahulu, sebelum berkas lainnya.** Ini akan membuat skema `lab4`, menyalin tabel `film`, dan mengisi tabel `jejak_akses` dengan 500.000 baris data acak. Setelah dijalankan, pastikan hasil `SELECT count(*)` di akhir menunjukkan angka **500000** — kalau belum, jangan lanjut ke soal berikutnya.

## Urutan Pengerjaan

File dikerjakan berurutan dari Q1 sampai Q21, karena beberapa soal bergantung pada objek yang dibuat di soal sebelumnya (contoh: Q3 mengubah ulang view yang dibuat di Q1, Q10–Q13 butuh trigger dari Q9, Q19 butuh tabel dari Q18, dst).

1. **Q1–Q4** — View dan `WITH CHECK OPTION`
2. **Q5–Q8** — Materialized view dan refresh concurrent
3. **Q9–Q13** — Trigger audit (level baris & level pernyataan)
4. **Q14–Q17** — Constraint (`CHECK NOT VALID`, unique index parsial, foreign key, `EXCLUDE`)
5. **Q18–Q21** — Pola Expand–Contract untuk migrasi skema yang aman

## Dua Sesi yang Dibutuhkan

Ada dua soal yang mengharuskan dua sesi psql berjalan bersamaan:

- **Q8** — sesi 1 menjalankan insert data lalu refresh materialized view, sesi 2 langsung query ke materialized view di saat yang sama, untuk membuktikan `REFRESH CONCURRENTLY` tidak memblokir pembaca.
- **Q20** — sesi pembaca dijalankan terus-menerus (`SELECT title, rental_rate FROM lab4.film LIMIT 5;`) sepanjang proses expand–contract berlangsung, untuk memastikan pembaca lama tidak pernah gagal di tengah migrasi.

Buka dua terminal terpisah untuk kedua kasus ini, masing-masing masuk ke psql sendiri-sendiri.

## Peringatan: Migrasi 0046 Tidak Bisa Dipulihkan Penuh

Migrasi `0046_contract_drop_kolom_lama` menghapus kolom `rental_rate` lama dari `lab4.film`. Walaupun ada berkas `.down.sql` untuk migrasi ini, file itu hanya bisa membuat ulang kolomnya — **bukan mengembalikan isinya**. Data yang sudah terhapus lewat `DROP COLUMN` hilang permanen.

Karena itu, **jangan jalankan migrasi 0046 sebelum**:
- Verifikasi backfill (Q19) sudah menghasilkan nol selisih
- View fasad dari Q20/0045 sudah terpasang dan terbukti stabil
- Sesi pembaca lama sudah dipastikan tidak error selama proses berjalan

Kalau masih ragu, tunda dulu 0046 sampai semua bukti di atas terkumpul dan sudah didiskusikan bareng kelompok.

## Struktur Berkas

latihan/p04/
├── README.md
├── laporan.md
├── q00_setup.sql
├── q01_view_film_murah.sql
├── q02_baris_menghilang.sql
├── q03_check_option.sql
├── q04_view_pendapatan_kategori.sql
├── ... (q05 sampai q21)
└── struktur_migrations.png

migrations/
├── 0041_expand_buat_harga_film.up.sql
├── 0041_expand_buat_harga_film.down.sql
├── 0042_expand_trigger_tulis_ganda.up.sql
├── 0042_expand_trigger_tulis_ganda.down.sql
├── 0043_migrate_backfill.up.sql
├── 0043_migrate_backfill.down.sql
├── 0044_migrate_verifikasi.up.sql
├── 0044_migrate_verifikasi.down.sql
├── 0045_contract_view_fasad.up.sql
├── 0045_contract_view_fasad.down.sql
├── 0046_contract_drop_kolom_lama.up.sql
└── 0046_contract_drop_kolom_lama.down.sql