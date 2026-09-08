# Laporan Latihan Kelompok Pertemuan 3

## Anggota

| Nama                       | NIM       |
| -------------------------- | --------- |
| Jelita Hati Sinurat        | 251402141 |
| M. Dzakwan Ismail Rangkuti | 251402014 |
| Agi Aginta Sembiring       | 251402059 |
| M. Azkha Amorie            | 251402092 |
| Syifa Nazira               | 251402126 |

## Refleksi A - Subquery

**1. Pada Q4, apa tepatnya yang membuat `NOT IN` berbahaya, dan bagaimana memeriksa apakah sebuah kolom rawan terhadap masalah itu?**

`NOT IN` bisa berbahaya kalau subquery di dalamnya ternyata bisa menghasilkan nilai NULL. Soalnya `kolom NOT IN (SELECT x FROM t)` itu di baliknya sama aja kayak `kolom <> v1 AND kolom <> v2 AND ...` buat tiap nilai v yang dihasilkan subquery. Masalahnya, bandingin apa pun sama NULL (`<> NULL`) hasilnya bukan TRUE atau FALSE, tapi UNKNOWN — dan karena semua kondisi itu digabung pakai AND, cukup satu aja NULL nyelip di daftar hasil subquery, seluruh `NOT IN`-nya jadi UNKNOWN buat setiap baris. Akibatnya query bisa balikin nol baris sama sekali, padahal harusnya ada yang cocok.

Di Q4 kami, kolom yang dipakai di subquery adalah `inventory.film_id`, yang di skema Pagila memang `NOT NULL`, jadi versi `NOT IN` di sini aman-aman aja dan hasilnya sama persis kayak `NOT EXISTS` (sama-sama 42 baris). Buat ngecek kolom lain rawan atau nggak, caranya: cek dulu constraint-nya lewat `\d nama_tabel` di psql, kalau nggak ada `NOT NULL` di situ, jalanin `SELECT count(*) FROM tabel WHERE kolom IS NULL;` buat mastiin datanya bener-bener bersih dari NULL. Tapi paling aman sih emang jadiin kebiasaan: tambahin `WHERE kolom IS NOT NULL` di subquery-nya `NOT IN`, atau langsung pakai `NOT EXISTS` aja karena dia nggak kepengaruh NULL sama sekali — dia kerja berdasarkan ada/nggaknya baris yang cocok, bukan bandingin nilai satu-satu.

**2. Pada Q5, berapa kali subquery dievaluasi secara konseptual, dan mengapa "sekali per baris luar" belum tentu sama dengan yang benar-benar dikerjakan mesin?**

Q5 pakai subquery berkorelasi dengan `MAX(f2.rental_rate)` yang disaring `WHERE i2.store_id = i.store_id`, buat nyari tarif tertinggi per toko. Kalau dibayangin secara konsep, subquery ini kayak dihitung ulang satu kali buat tiap baris di query luar, soalnya dia nyambung ke `store_id` dari baris luar — jadi model sederhananya, subquery "dijalanin" sebanyak baris hasil join `film`-`inventory` yang lagi diperiksa (ribuan kali kalau dibayangin naif).

Tapi kenyataannya di eksekusi asli, nggak sesederhana itu. Hasil Q5 kami nunjukin 500 baris kesebar di 2 toko (`store_id` 1 dan 2), dan semuanya tarifnya 4.99 — nilai tertinggi dari cuma 3 kemungkinan tarif yang ada di Pagila (0.99, 2.99, 4.99). Karena nilai `rental_rate` variasinya dikit banget, PostgreSQL nggak perlu literally ngitung ulang `MAX` satu-satu per baris; query planner-nya bisa ngenalin pola subquery berkorelasi ini terus diubah jadi bentuk join/agregasi yang lebih optimal (misalnya, ngitung `MAX(rental_rate)` per `store_id` sekali doang pakai hash aggregate, baru dijoinin balik) — ini bisa dicek pakai `EXPLAIN ANALYZE`. Jadi "sekali per baris luar" itu berguna buat ngerti _logika_ hasilnya (nilai pembandingnya emang beda-beda tergantung toko di baris itu), tapi bukan gambaran akurat soal berapa kali mesinnya beneran ngerjain — itu semua tergantung strategi optimasi planner, yang biasanya jauh lebih hemat daripada diulang mentah-mentah per baris.

## Refleksi B - CTE dan Recursive CTE

...

## Refleksi C - Window Function

...

## Refleksi D - Agregasi dan Operasi Himpunan

...

## Refleksi E - JSONB

...

## Temuan Q14

...

## Hasil R1

![Sepuluh baris pertama](r1_10_baris.png)

## Kontribusi dan Commit

| Nama                       | Kontribusi                                  | Commit               |
| -------------------------- | ------------------------------------------- | -------------------- |
| Jelita Hati Sinurat        | q00_setup.sql, Q1-Q5 (subquery), Refleksi A | (isi setelah commit) |
| M. Dzakwan Ismail Rangkuti |                                             |                      |
| Agi Aginta Sembiring       |                                             |                      |
| M. Azkha Amorie            |                                             |                      |
| Syifa Nazira               |                                             |                      |

## Tautan Merge Request

...
