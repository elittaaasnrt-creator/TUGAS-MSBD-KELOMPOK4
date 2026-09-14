### Q6

_(diisi Mael)_

### Q7

_(diisi Mael)_

---

## Refleksi A–E

### Refleksi A (Jelita)

Menempatkan seluruh akses aplikasi lewat view memang punya beberapa keuntungan. Pertama, view bisa menyembunyikan struktur tabel asli dari aplikasi — kalau suatu saat skema tabel dasar berubah, aplikasi tidak perlu ikut berubah selama view-nya masih menyediakan kolom yang sama. Kedua, view mempermudah penerapan aturan akses, misalnya membatasi aplikasi hanya boleh melihat/mengubah data yang memenuhi kondisi tertentu (seperti `film_murah` yang membatasi `rental_rate <= 0.99`).

Tapi ada juga kerugiannya. Pertama, seperti yang terlihat di Q2, view tanpa `CHECK OPTION` bisa menyesatkan — aplikasi bisa saja berhasil insert data yang sebenarnya melanggar aturan bisnis, dan baru sadar ada masalah karena data "menghilang" dari tampilan, bukan karena ada pesan error yang jelas. Ini bisa bikin bug sulit dilacak. Kedua, seperti di Q4, tidak semua view bisa langsung dipakai untuk insert/update — view yang mengandung `GROUP BY` atau agregasi butuh trigger tambahan (`INSTEAD OF`) supaya bisa ditulisi, jadi tidak bisa diasumsikan semua view otomatis mendukung operasi tulis.

Contoh konkret dari pengamatan Q1–Q4: kasus di Q2 adalah yang paling berisiko kalau tidak disadari. Bayangkan aplikasi produksi memakai view `film_murah` sebagai satu-satunya jalur insert data film murah untuk promo. Tanpa `CHECK OPTION`, staff yang input harga salah (misalnya kelebihan ketik jadi 4.99 padahal maksudnya 0.99) tidak akan mendapat error apa pun — datanya tetap masuk ke database, tapi tidak pernah muncul di laporan promo karena difilter oleh view. Kesalahan data baru ketahuan belakangan, mungkin saat audit, dan sudah terlambat. Ini justru mempersulit tim karena kesalahan seperti ini "senyap" — tidak ada log, tidak ada error, tidak ada alert.

### Refleksi B (Mael)

_(diisi)_

### Refleksi C (Agi)

_(diisi)_

### Refleksi D (Azkha)

_(diisi)_

### Refleksi E (Syifa)

_(diisi)_

---

## Ringkasan Waktu

| Tugas | Waktu | Penafsiran |
| ----- | ----: | ---------- |
| Q5    |       |            |
| Q6    |       |            |
| Q7    |       |            |
| Q12   |       |            |
| Q13   |       |            |

---

## Migrasi dan Commit

- Struktur `migrations/`: _(screenshot + penjelasan, diisi Syifa)_
- Tautan Merge Request: _(diisi Jelita setelah semua branch digabung)_
- Catatan sesi pembaca (Q8, Q20): _(diisi oleh Mael dan Syifa)_
