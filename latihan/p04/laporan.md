# Laporan Latihan Kelompok Pertemuan 4

## SQL Lanjutan II: Audit Log, Materialized View, dan Migrasi Aman

## Identitas Kelompok

| Nama                       | NIM       | Kontribusi                                             | Commit |
| -------------------------- | --------- | ------------------------------------------------------ | ------ |
| Jelita Hati Sinurat        | 251402141 | q00_setup.sql, Q1–Q4 (View & Check Option), Refleksi A |        |
| M. Dzakwan Rangkuti (Mael) | 251402014 | Q5–Q8 (Materialized View), Refleksi B                  |        |
| Agi Aginta Sembiring       | 251402059 | Q9–Q13 (Trigger Audit), Refleksi C                     |        |
| M. Azkha Amorie            | 251402092 | Q14–Q17 (Constraint), Refleksi D                       |        |
| Syifa Nazira               | 251402126 | Q18–Q21 (Expand–Contract) + migrations/, Refleksi E    |        |

---

## Q1–Q21

### Q1 — View film_murah

Perintah:

```sql
CREATE VIEW lab4.film_murah AS
SELECT film_id, title, rental_rate, rating
FROM lab4.film
WHERE rental_rate <= 0.99;
```

Keluaran: `CREATE VIEW`

Alasan: View sederhana dengan `WHERE`, tanpa check option dulu, sesuai instruksi Q1 (check option baru ditambahkan di Q3 untuk perbandingan).

### Q2 — Baris menghilang

Perintah: `INSERT` lewat view `film_murah` dengan `rental_rate = 4.99`, lalu bandingkan jumlah baris di view vs tabel dasar.

Keluaran: `di_view = 0`, `di_tabel_dasar = 1`

Alasan: Baris berhasil masuk ke tabel dasar karena view tanpa check option hanya menyaring tampilan (`SELECT`), bukan memvalidasi input (`INSERT`). Baris menjadi "hilang" dari view karena tidak memenuhi `WHERE rental_rate <= 0.99`, meski tetap ada di tabel `lab4.film`.

### Q3 — WITH CASCADED CHECK OPTION

Perintah:

```sql
CREATE OR REPLACE VIEW lab4.film_murah AS
SELECT film_id, title, rental_rate, rating
FROM lab4.film
WHERE rental_rate <= 0.99
WITH CASCADED CHECK OPTION;
```

Keluaran: `CREATE VIEW`, lalu `INSERT` dengan `rental_rate = 4.99` ditolak (pesan galat lengkap di bagian Pesan Galat Utuh).

Alasan: Dengan `CASCADED CHECK OPTION`, PostgreSQL memvalidasi data sebelum masuk, bukan hanya menyaring tampilan.

### Q4 — View pendapatan_kategori (GROUP BY)

Perintah:

```sql
CREATE VIEW lab4.pendapatan_kategori AS
SELECT c.name AS kategori,
       SUM(p.amount) AS total_pendapatan
FROM public.category c
JOIN public.film_category fc ON fc.category_id = c.category_id
JOIN public.inventory i ON i.film_id = fc.film_id
JOIN public.rental r ON r.inventory_id = i.inventory_id
JOIN public.payment p ON p.rental_id = r.rental_id
GROUP BY c.name;
```

Keluaran: `CREATE VIEW` berhasil, percobaan `INSERT` gagal (pesan galat lengkap di bagian Pesan Galat Utuh).

Alasan: View dengan `GROUP BY`/agregasi tidak punya pemetaan 1-ke-1 ke baris tabel dasar, sehingga PostgreSQL tidak tahu ke baris mana nilai baru harus ditulis — makanya tidak auto-updatable.

### Q5 — Query dasar akses

Perintah:

```sql
\timing on

SELECT date_trunc('month', a.waktu) AS bulan,
       a.kanal,
       count(*) AS jumlah_akses,
       count(DISTINCT a.film_id) AS film_unik
FROM lab4.jejak_akses a
GROUP BY 1, 2
ORDER BY 1, 2;
```

Keluaran: Waktu eksekusi 441.836 ms (lihat Ringkasan Waktu).

Alasan: `\timing on` dipakai untuk mencatat durasi eksekusi query dasar sebagai baseline, dibandingkan `EXPLAIN ANALYZE` yang tidak dipilih karena soal secara spesifik meminta waktu eksekusi aktual lewat `\timing`.

### Q6 — Membuat materialized view

Perintah:

```sql
CREATE MATERIALIZED VIEW lab4.ringkasan_akses AS
SELECT date_trunc('month', a.waktu) AS bulan,
       a.kanal,
       count(*) AS jumlah_akses,
       count(DISTINCT a.film_id) AS film_unik
FROM lab4.jejak_akses a
GROUP BY 1, 2
ORDER BY 1, 2
WITH NO DATA;

SELECT * FROM lab4.ringkasan_akses;  -- menghasilkan galat, lihat Pesan Galat Utuh

\timing on
REFRESH MATERIALIZED VIEW lab4.ringkasan_akses;
```

Keluaran: `CREATE MATERIALIZED VIEW`, lalu `SELECT` gagal dengan pesan galat "has not been populated" (lihat Pesan Galat Utuh), lalu `REFRESH` biasa berhasil dalam 494.398 ms.

Alasan: Opsi `WITH NO DATA` dipilih agar bisa membuktikan status unpopulated sebelum di-refresh, dibanding langsung dibuat dengan data (default) yang tidak akan menunjukkan pesan galat tersebut.

### Q7 — Refresh concurrently

Perintah:

```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY lab4.ringkasan_akses;  -- galat, lihat Pesan Galat Utuh

CREATE UNIQUE INDEX ux_ringkasan_akses ON lab4.ringkasan_akses (bulan, kanal);

\timing on
REFRESH MATERIALIZED VIEW CONCURRENTLY lab4.ringkasan_akses;
```

Keluaran: Percobaan pertama gagal (pesan galat di bagian Pesan Galat Utuh), lalu setelah `UNIQUE INDEX` dibuat, `REFRESH CONCURRENTLY` berhasil dalam 572.396 ms.

Alasan: `UNIQUE INDEX` pada kombinasi kolom `(bulan, kanal)` dipilih karena kombinasi itu menjamin keunikan tiap baris di materialized view — syarat wajib PostgreSQL untuk mengizinkan refresh non-blocking.

### Q8 — Membuktikan pembaca tidak terblokir

Perintah (dua sesi terpisah):

```sql
-- Sesi 1
INSERT INTO lab4.jejak_akses (film_id, waktu, kanal)
SELECT (random() * 999)::int + 1, now(), 'web'
FROM generate_series(1, 200000);

REFRESH MATERIALIZED VIEW lab4.ringkasan_akses;               -- pengujian A, memblokir sesi 2
REFRESH MATERIALIZED VIEW CONCURRENTLY lab4.ringkasan_akses;  -- pengujian B, tidak memblokir sesi 2

-- Sesi 2 (dijalankan bersamaan)
SELECT count(*) FROM lab4.ringkasan_akses;
```

Keluaran: Lihat penjelasan lengkap di bagian "Catatan sesi pembaca (Q8, Q20)" — `REFRESH` biasa memblokir `SELECT` di sesi 2 sampai refresh selesai, sedangkan `REFRESH CONCURRENTLY` tidak.

Alasan: Dua sesi psql terpisah dipilih untuk mensimulasikan kondisi pembaca dan penulis yang berjalan bersamaan secara nyata, dibanding `LOCK TABLE` manual yang tidak merepresentasikan mekanisme refresh bawaan PostgreSQL.

### Q9 — Trigger audit level baris

Perintah:

```sql
CREATE TABLE lab4.audit_harga (
    audit_id bigserial PRIMARY KEY,
    film_id integer NOT NULL,
    harga_lama numeric(5,2),
    harga_baru numeric(5,2),
    diubah_oleh text NOT NULL DEFAULT current_user,
    diubah_pada timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION lab4.catat_audit_harga()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO lab4.audit_harga (film_id, harga_lama, harga_baru, diubah_oleh, diubah_pada)
    VALUES (OLD.film_id, OLD.rental_rate, NEW.rental_rate, current_user, now());
    RETURN NEW;
END;
$$;

CREATE TRIGGER film_audit_harga
AFTER UPDATE OF rental_rate ON lab4.film
FOR EACH ROW
WHEN (OLD.rental_rate IS DISTINCT FROM NEW.rental_rate)
EXECUTE FUNCTION lab4.catat_audit_harga();
```

Keluaran: `CREATE TABLE`, `CREATE FUNCTION`, `CREATE TRIGGER` berhasil.

Alasan: Trigger memakai `AFTER UPDATE OF rental_rate` (bukan `AFTER UPDATE` polos) supaya hanya perubahan `rental_rate` yang memicu trigger, dan kondisi `WHEN (OLD.rental_rate IS DISTINCT FROM NEW.rental_rate)` mencegah audit tercatat kalau nilainya ditulis ulang dengan angka yang sama.

### Q10 — Uji audit baris

Perintah:

```sql
TRUNCATE TABLE lab4.audit_harga;

UPDATE lab4.film SET rental_rate = rental_rate + 0.01 WHERE film_id = 1;  -- mengubah harga
UPDATE lab4.film SET rental_rate = rental_rate WHERE film_id = 1;        -- menulis ulang harga sama
UPDATE lab4.film SET title = title WHERE film_id = 1;                    -- mengubah title saja

SELECT * FROM lab4.audit_harga ORDER BY audit_id;
```

Keluaran: Hanya `UPDATE` pertama yang menghasilkan satu baris baru di `lab4.audit_harga`; dua `UPDATE` berikutnya tidak menghasilkan baris audit sama sekali.

Alasan: `UPDATE` kedua tidak tercatat karena klausa `WHEN` menolak perubahan yang nilainya identik (`OLD` sama dengan `NEW`). `UPDATE` ketiga tidak tercatat karena trigger memakai `AFTER UPDATE OF rental_rate`, jadi perubahan pada kolom lain (`title`) sama sekali tidak memicu trigger.

### Q11 — NULL pada trigger

Perintah:

```sql
DROP TRIGGER IF EXISTS film_audit_harga ON lab4.film;

CREATE TRIGGER film_audit_harga
AFTER UPDATE OF rental_rate ON lab4.film
FOR EACH ROW
WHEN (OLD.rental_rate <> NEW.rental_rate)
EXECUTE FUNCTION lab4.catat_audit_harga();

UPDATE lab4.film SET rental_rate = NULL WHERE film_id = 1;
UPDATE lab4.film SET rental_rate = 2.99 WHERE film_id = 1;

SELECT * FROM lab4.audit_harga ORDER BY audit_id;
```

Keluaran: Kedua `UPDATE` (ke `NULL` dan dari `NULL` kembali ke angka) tidak menghasilkan baris audit sama sekali.

Alasan: Ini murni akibat logika tiga nilai (three-valued logic) pada `NULL` di SQL. Operator `<>` yang dibandingkan dengan `NULL` di salah satu sisi selalu menghasilkan `NULL` (bukan `TRUE`/`FALSE`), dan klausa `WHEN` memperlakukan hasil `NULL` sebagai "tidak terpenuhi" — jadi trigger tidak pernah jalan setiap kali salah satu nilai (lama atau baru) adalah `NULL`. Inilah alasan `IS DISTINCT FROM` (di Q9/Q10) lebih aman dipakai daripada `<>`, karena `IS DISTINCT FROM` memperlakukan `NULL` secara eksplisit dan tetap menghasilkan `TRUE`/`FALSE`.

### Q12 — Biaya trigger baris

Perintah:

```sql
ALTER TABLE lab4.film ENABLE TRIGGER film_audit_harga;

EXPLAIN (ANALYZE, BUFFERS)
UPDATE lab4.film SET rental_rate = rental_rate + 0.01;   -- trigger aktif

ALTER TABLE lab4.film DISABLE TRIGGER film_audit_harga;

EXPLAIN (ANALYZE, BUFFERS)
UPDATE lab4.film SET rental_rate = rental_rate + 0.01;   -- trigger nonaktif

ALTER TABLE lab4.film ENABLE TRIGGER film_audit_harga;
```

Keluaran: Waktu eksekusi 75.605 ms saat trigger aktif vs 32.363 ms saat trigger nonaktif — overhead sebesar 45.731 ms untuk 10.000 baris (lihat Ringkasan Waktu).

Alasan: `EXPLAIN (ANALYZE, BUFFERS)` dipakai untuk mengukur waktu eksekusi aktual sekaligus buffer I/O, sehingga bisa dibandingkan apple-to-apple dengan kondisi trigger nonaktif.

### Q13 — Trigger level pernyataan

Perintah:

```sql
CREATE OR REPLACE FUNCTION lab4.catat_audit_massal()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO lab4.audit_harga (film_id, harga_lama, harga_baru, diubah_oleh, diubah_pada)
    SELECT baru.film_id, lama.rental_rate, baru.rental_rate, current_user, now()
    FROM lama JOIN baru ON lama.film_id = baru.film_id
    WHERE lama.rental_rate IS DISTINCT FROM baru.rental_rate;
    RETURN NULL;
END;
$$;

CREATE TRIGGER film_audit_harga_massal
AFTER UPDATE ON lab4.film
REFERENCING OLD TABLE AS lama NEW TABLE AS baru
FOR EACH STATEMENT
EXECUTE FUNCTION lab4.catat_audit_massal();

ALTER TABLE lab4.film DISABLE TRIGGER film_audit_harga;

EXPLAIN (ANALYZE, BUFFERS)
UPDATE lab4.film SET rental_rate = rental_rate + 0.01;

ALTER TABLE lab4.film ENABLE TRIGGER film_audit_harga;
```

Keluaran: Waktu eksekusi 55.664 ms untuk 10.000 baris, dengan fungsi trigger hanya dipanggil 1 kali (`calls=1`) — lebih cepat dibanding trigger level baris di Q12 (lihat Ringkasan Waktu).

Alasan: `REFERENCING OLD TABLE ... NEW TABLE` (transition table) dipilih agar seluruh baris yang berubah bisa diaudit dalam satu `INSERT ... SELECT`, bukan satu `INSERT` per baris seperti trigger `FOR EACH ROW`. Trigger `film_audit_harga` (level baris) sengaja dinonaktifkan dulu supaya kedua mekanisme audit tidak tercatat dobel saat pengujian.

### Q14 — CHECK NOT VALID

Perintah:

```sql
UPDATE lab4.film SET rental_rate = -1.00 WHERE film_id = 1;

ALTER TABLE lab4.film
ADD CONSTRAINT film_rental_rate_nonneg
CHECK (rental_rate >= 0) NOT VALID;

SELECT film_id, title, rental_rate FROM lab4.film WHERE film_id = 1;

ALTER TABLE lab4.film VALIDATE CONSTRAINT film_rental_rate_nonneg;  -- gagal, masih ada data negatif

UPDATE lab4.film SET rental_rate = 0.99 WHERE film_id = 1;

ALTER TABLE lab4.film VALIDATE CONSTRAINT film_rental_rate_nonneg;  -- berhasil

SELECT count(*) AS data_negatif FROM lab4.film WHERE rental_rate < 0;
```

Keluaran: Tahap `ADD CONSTRAINT ... NOT VALID` berhasil meski ada data negatif di tabel. Tahap `VALIDATE CONSTRAINT` pertama gagal karena `film_id = 1` masih bernilai -1.00. Setelah data diperbaiki ke 0.99, `VALIDATE CONSTRAINT` kedua berhasil, dan `data_negatif` = 0.

Alasan: `NOT VALID` dipilih agar constraint bisa langsung dipasang tanpa memeriksa seluruh data lama terlebih dulu (menghindari lock lama pada tabel besar), baru divalidasi belakangan lewat `VALIDATE CONSTRAINT` — berbeda dengan `ADD CONSTRAINT` biasa yang akan langsung gagal total kalau ada satu saja data lama yang melanggar.

### Q15 — Unique index parsial untuk soft delete

Perintah:

```sql
ALTER TABLE lab4.film ADD COLUMN IF NOT EXISTS deleted_at timestamptz;
UPDATE lab4.film SET deleted_at = now() WHERE film_id = 1;

ALTER TABLE lab4.film ADD CONSTRAINT film_judul_unik UNIQUE (title);

-- Insert ulang judul yang sudah soft-delete — seharusnya GAGAL
INSERT INTO lab4.film (..., deleted_at)
SELECT ..., NULL FROM lab4.film WHERE film_id = 1;

ALTER TABLE lab4.film DROP CONSTRAINT film_judul_unik;

CREATE UNIQUE INDEX ux_film_judul_aktif
ON lab4.film (title) WHERE deleted_at IS NULL;

-- Insert ulang lagi — sekarang diperbolehkan
INSERT INTO lab4.film (..., deleted_at)
SELECT ..., NULL FROM lab4.film WHERE film_id = 1;

SELECT film_id, title, deleted_at FROM lab4.film
WHERE title = (SELECT title FROM lab4.film WHERE film_id = 1);
```

Keluaran: Dengan `UNIQUE` biasa, insert judul yang sama (walau baris lamanya sudah soft-delete) ditolak dengan pelanggaran unique constraint. Setelah diganti ke unique index parsial (`WHERE deleted_at IS NULL`), insert judul yang sama berhasil, karena hanya baris aktif yang ikut diperiksa keunikannya.

Alasan: `UNIQUE` biasa memeriksa seluruh baris tanpa peduli status soft-delete, sehingga judul yang "sudah dihapus" tetap dianggap ada dan menghalangi pendaftaran ulang. Unique index parsial dipilih karena hanya menegakkan keunikan pada baris yang `deleted_at IS NULL` (masih aktif) — pendekatan `UNIQUE(title, deleted_at)` tidak dipilih karena nilai `NULL` pada kolom kedua bisa membuat PostgreSQL menganggap tiap baris "berbeda", sehingga proteksi keunikan jadi tidak konsisten.

### Q16 — Aksi referensial foreign key

Perintah:

```sql
-- NO ACTION
CREATE TABLE lab4.ulasan_no_action (... FOREIGN KEY (film_id) REFERENCES lab4.film (film_id) ON DELETE NO ACTION);
INSERT INTO lab4.ulasan_no_action (film_id, komentar) VALUES (2, 'Uji NO ACTION');
DELETE FROM lab4.film WHERE film_id = 2;   -- seharusnya gagal

-- CASCADE
CREATE TABLE lab4.ulasan_cascade (... ON DELETE CASCADE);
INSERT INTO lab4.ulasan_cascade (film_id, komentar) VALUES (3, 'Uji CASCADE');
DELETE FROM lab4.film WHERE film_id = 3;   -- baris ulasan ikut terhapus
SELECT * FROM lab4.ulasan_cascade WHERE film_id = 3;

-- SET NULL
CREATE TABLE lab4.ulasan_set_null (... ON DELETE SET NULL);
INSERT INTO lab4.ulasan_set_null (film_id, komentar) VALUES (4, 'Uji SET NULL');
DELETE FROM lab4.film WHERE film_id = 4;   -- baris tetap ada, film_id jadi NULL
SELECT * FROM lab4.ulasan_set_null WHERE ulasan_id = 1;
```

Ringkasan perilaku:

| Aksi      | Perilaku saat induk dihapus                                                          |
| --------- | ------------------------------------------------------------------------------------ |
| NO ACTION | `DELETE` pada `lab4.film` ditolak selama masih ada baris anak yang mereferensikannya |
| CASCADE   | Baris anak yang mereferensikan ikut terhapus otomatis                                |
| SET NULL  | Baris anak tetap ada, tapi kolom `film_id`-nya diubah jadi `NULL`                    |

Alasan: Tiga tabel uji terpisah dipakai supaya masing-masing aksi referensial bisa diamati secara independen tanpa saling mengganggu hasil pengujian yang lain.

### Q17 — EXCLUDE untuk periode harga

Perintah:

```sql
CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE lab4.harga_film (
    harga_film_id bigserial PRIMARY KEY,
    film_id integer NOT NULL REFERENCES lab4.film (film_id),
    wilayah text NOT NULL,
    harga numeric(5,2) NOT NULL CHECK (harga >= 0),
    berlaku daterange NOT NULL,
    CONSTRAINT harga_film_tidak_overlap
        EXCLUDE USING gist (film_id WITH =, wilayah WITH =, berlaku WITH &&)
);

INSERT INTO lab4.harga_film (film_id, wilayah, harga, berlaku)
VALUES (5, 'ID', 10.00, daterange('2026-01-01', '2026-04-01'));   -- diterima

INSERT INTO lab4.harga_film (film_id, wilayah, harga, berlaku)
VALUES (5, 'ID', 12.00, daterange('2026-04-01', '2026-07-01'));   -- diterima, periode beda

INSERT INTO lab4.harga_film (film_id, wilayah, harga, berlaku)
VALUES (5, 'ID', 15.00, daterange('2026-03-01', '2026-05-01'));   -- DITOLAK, overlap

INSERT INTO lab4.harga_film (film_id, wilayah, harga, berlaku)
VALUES (5, 'MY', 15.00, daterange('2026-03-01', '2026-05-01'));   -- diterima, wilayah beda
```

Keluaran: Dua insert pertama berhasil karena periodenya tidak beririsan. Insert ketiga ditolak dengan pelanggaran `EXCLUDE` karena periodenya (Maret–Mei) beririsan dengan periode kedua (April–Juli) untuk `film_id` dan `wilayah` yang sama. Insert keempat berhasil walau periodenya sama dengan yang ditolak, karena wilayahnya beda (`MY` vs `ID`).

Alasan: `EXCLUDE USING gist` dengan kombinasi `film_id WITH =, wilayah WITH =, berlaku WITH &&` dipilih karena aturan bisnisnya melibatkan kombinasi identitas (film + wilayah) dan irisan rentang tanggal (`&&`) sekaligus — sesuatu yang tidak bisa ditangani `CHECK` atau `UNIQUE` biasa. Alternatif trigger yang mengecek overlap manual sebelum `INSERT` tidak dipilih karena rentan race condition saat dua transaksi berjalan bersamaan (dibahas lebih lanjut di Refleksi D).

### Q18 — Expand: struktur baru + tulis ganda

Perintah:

```sql
CREATE TABLE IF NOT EXISTS lab4.harga_film (
    harga_id bigserial PRIMARY KEY,
    film_id integer NOT NULL REFERENCES lab4.film(film_id),
    wilayah text NOT NULL DEFAULT 'ID',
    harga numeric(5,2) NOT NULL CHECK (harga >= 0),
    berlaku daterange NOT NULL DEFAULT daterange('2026-01-01', NULL)
);

CREATE OR REPLACE FUNCTION lab4.fn_tulis_ganda_harga()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO lab4.harga_film (film_id, wilayah, harga)
    VALUES (NEW.film_id, 'ID', NEW.rental_rate)
    ON CONFLICT DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tulis_ganda_harga
AFTER INSERT OR UPDATE OF rental_rate ON lab4.film
FOR EACH ROW
EXECUTE FUNCTION lab4.fn_tulis_ganda_harga();
```

Keluaran: `CREATE TABLE`, `CREATE FUNCTION`, `CREATE TRIGGER` berhasil. Sesi pembaca yang menjalankan `SELECT title, rental_rate FROM lab4.film LIMIT 5;` tetap berjalan normal tanpa gangguan.

Alasan: Trigger `AFTER INSERT OR UPDATE OF rental_rate` dipilih agar setiap perubahan harga di `lab4.film` langsung tercermin ke `lab4.harga_film` secara real-time, dibanding sinkronisasi periodik (batch) yang tidak dipilih karena ada jeda waktu yang berisiko membuat kedua tabel tidak konsisten selama masa transisi.

### Q19 — Backfill bertahap

Perintah:

```sql
INSERT INTO lab4.harga_film (film_id, wilayah, harga, berlaku)
SELECT f.film_id, 'ID', f.rental_rate, daterange('2026-01-01', NULL)
FROM lab4.film f
WHERE f.film_id BETWEEN 1 AND 1000
  AND NOT EXISTS (
      SELECT 1 FROM lab4.harga_film h
      WHERE h.film_id = f.film_id AND h.wilayah = 'ID'
  );

SELECT count(*)
FROM lab4.film f
WHERE NOT EXISTS (
    SELECT 1 FROM lab4.harga_film h
    WHERE h.film_id = f.film_id AND h.wilayah = 'ID'
);
```

Keluaran: Backfill 1.000 film pertama berhasil, verifikasi `count(*)` menghasilkan 0 (data Pagila hanya berisi 1.000 film, jadi satu batch backfill sudah mencakup semuanya).

Alasan: Backfill dilakukan per rentang `film_id` (potongan 1.000), bukan satu `UPDATE`/`INSERT` besar sekaligus, supaya lock pada tabel tidak berlangsung lama dan proses bisa dijeda/diulang per bagian tanpa mengunci seluruh tabel sekaligus. Klausa `NOT EXISTS` memastikan backfill bersifat idempoten — aman dijalankan berulang tanpa membuat data ganda.

### Q20 — Contract: view fasad + drop kolom lama

Perintah:

```sql
DROP TRIGGER IF EXISTS trg_tulis_ganda_harga ON lab4.film;
DROP FUNCTION IF EXISTS lab4.fn_tulis_ganda_harga();

ALTER TABLE lab4.film DROP COLUMN IF EXISTS rental_rate;

CREATE OR REPLACE VIEW lab4.v_film_fasad AS
SELECT f.film_id, f.title, f.description, f.release_year, f.language_id,
       f.original_language_id, f.rental_duration,
       h.harga AS rental_rate,
       f.length, f.replacement_cost, f.rating, f.last_update,
       f.special_features, f.fulltext
FROM lab4.film f
LEFT JOIN lab4.harga_film h ON f.film_id = h.film_id AND h.wilayah = 'ID';
```

Keluaran: Trigger tulis ganda berhasil dihapus, kolom `rental_rate` lama berhasil di-drop dari `lab4.film`, dan view `lab4.v_film_fasad` berhasil dibuat menyajikan `rental_rate` (kini bersumber dari `lab4.harga_film` lewat `LEFT JOIN`) dengan struktur yang identik seperti sebelum migrasi. Catatan lengkap soal urutan eksekusi dan potensi kegagalan sesi pembaca ada di bagian "Catatan sesi pembaca (Q8, Q20)".

Alasan: Idealnya, view fasad dipasang dan aplikasi pembaca dialihkan terlebih dahulu, baru kolom lama di-drop — supaya pembaca lama tidak sempat error di antara dua langkah tersebut. Urutan eksekusi yang benar dan risikonya kalau dibalik dijelaskan lebih lanjut di catatan sesi pembaca di bawah.

### Q21 — Migrasi berversi dan rollback

Enam tahap Q18–Q20 dituliskan ulang sebagai enam pasang migrasi berversi (`.up.sql` dan `.down.sql`) di folder `migrations/`, mengikuti pola expand–migrate–contract:
