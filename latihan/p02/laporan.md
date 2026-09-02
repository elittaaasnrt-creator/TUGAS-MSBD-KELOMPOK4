# Laporan Latihan Mandiri — Pertemuan 2

## Dari Kebutuhan ke Skema Berversi

**Kelompok:** TUGAS-MSBD-KELOMPOK 4

**Anggota:**

- Jelita Hati Sinurat - 251402141 (elittaaasnrt-creator) — Project Manager
- M. Ismail Dzakwan Rangkuti - 251402014 (dzakwanrangkuti)
- Agi Aginta Sembiring - 251402059 (agisembiring263-pixel)
- M. Azkha Amorie - 251402092 (azkhaamorie)
- Syifa Nazira - 251402126 (ziraa94)

---

### Domain dan Alasan Pemilihan

Kelompok kami memilih domain peminjaman alat laboratorium. Batasannya cukup jelas: hanya mencakup katalog alat, peminjaman, pengembalian, dan perbaikan alat, tanpa masuk ke sistem akademik atau keuangan kampus.

Domain ini juga punya beberapa aturan bisnis yang tidak sederhana, di antaranya:

- Kuota peminjaman — anggota dibatasi jumlah maksimal unit yang boleh dipinjam dalam satu waktu.
- Denda keterlambatan — dihitung berdasarkan lama keterlambatan pengembalian.
- Alat yang sedang diperbaiki tidak boleh dipinjamkan.

Ketiga aturan tersebut membuat domain ini cocok untuk latihan, karena tidak cukup diselesaikan dengan struktur tabel biasa, tapi perlu constraint, trigger, atau logika di sisi aplikasi.
---

### Ringkasan Lingkup Sistem

Sistem mencakup empat hal utama: katalog alat beserta unit fisiknya, proses peminjaman dan pengembalian, perhitungan denda keterlambatan, dan riwayat perbaikan alat. Di luar itu tidak termasuk lingkup, seperti pengadaan alat baru, pembayaran denda, data induk mahasiswa, dan jadwal praktikum. Rincian lengkap ada di `kebutuhan.md`.

---

### Ringkasan Kebutuhan Data

Terdapat 8 kebutuhan data (KD-01 sampai KD-08), mencakup pendataan anggota, katalog jenis alat, unit fisik alat, transaksi peminjaman, detail item pinjaman, pengembalian, denda, dan riwayat perbaikan.

Beberapa aturan yang cukup penting: satu anggota maksimal meminjam 3 unit alat dalam satu waktu (KD-04), unit yang sedang dipinjam atau dalam perbaikan tidak bisa dipinjamkan lagi (KD-03), dan unit yang rusak saat dikembalikan otomatis berpindah status ke perbaikan (KD-06). Rincian tiap KD ada di `kebutuhan.md`.

---

### Penjelasan ERD

ERD terdiri dari 7 entitas: Anggota, Alat, Unit_Alat, Peminjaman, Detail_Pinjam, Denda, dan Perbaikan.

Anggota melakukan Peminjaman, dan satu peminjaman bisa berisi beberapa unit alat sekaligus. Karena itu, Peminjaman dan Unit_Alat tidak dihubungkan langsung, tapi melalui entitas asosiatif Detail_Pinjam, supaya tiap unit yang dipinjam dalam satu transaksi tercatat sebagai baris tersendiri lengkap dengan kondisi awal dan akhirnya.

Alat memiliki banyak Unit_Alat, untuk membedakan jenis alat (misalnya "Multimeter Digital") dengan unit fisiknya masing-masing yang punya nomor inventaris dan status sendiri.

Satu Peminjaman bisa dikenakan Denda jika terlambat, dan satu Unit_Alat bisa menjalani beberapa kali Perbaikan sepanjang riwayatnya.

Bukti: `erd.png`

---

### Status Migration

Migration pertama (V1 — skema awal) berhasil dijalankan lewat Flyway tanpa error. Tabel inti seperti `anggota` sudah terbentuk sesuai skema, lengkap dengan constraint (CHECK status anggota dan kuota peminjaman). Riwayat migration tercatat di `flyway_schema_history` dengan status Success.

Bukti: `bukti/flyway-info.png`, `bukti/migration-history.png`


---

### Bukti Database Dapat Dibangun Ulang

Database `proyek_dev` di-drop lalu dibuat ulang dari kosong, kemudian migration dijalankan ulang dari awal. Hasilnya berhasil membangun kembali skema versi 1 tanpa error, dibuktikan lewat `flyway info` yang menunjukkan migration versi 1 kembali berstatus Success. Ini membuktikan seluruh struktur database bisa dibangun ulang murni dari file migration.

Bukti: `bukti/rebuild-database.png`

---

### Pola Tiga Langkah Penambahan Kolom NOT NULL

Penambahan kolom `kuota_maksimal` pada tabel `anggota` dilakukan lewat tiga migration terpisah: kolom ditambahkan sebagai nullable, data lama diisi nilai default, lalu kolom diubah menjadi NOT NULL sekaligus ditambahkan constraint `ck_kuota_positif` (nilai harus lebih dari 0). Hasil akhirnya terverifikasi lewat `\d anggota`, kolom sudah berstatus `not null` tanpa ada baris yang gagal diperbarui.

Bukti: `bukti/kolom-not-null.jpeg`

---

### Eksperimen Locking dan Pengamatan pg_stat_activity

TODO

Bukti: `bukti/pg-stat-activity.png`

---

### Hasil Seed Data (dijalankan dua kali)

Seed data dijalankan dua kali berturut-turut dengan perintah yang sama. Kedua eksekusi sama-sama melaporkan `INSERT 0 3`, dan hasil `SELECT count(*)` tetap menunjukkan 3 baris, tanpa data ganda. Seed data terbukti idempoten.

Bukti: `bukti/idempotent-seed-proof.png`

---

### Jawaban Pertanyaan 1–7

**1. Mengapa lingkungan pengujian memerlukan basis data sendiri, dan bukan sekadar schema terpisah di dalam basis data yang sama?**

> Lingkungan pengujian butuh basis data sendiri karena kita sering sengaja masukin data aneh atau data rusak buat nguji constraint dan aturan bisnis, jadi kalau cuma dipisah pakai schema saja, resikonya masih satu database yang sama dan bisa saja terpengaruh kalau ada konfigurasi yang salah. Selain itu proyek_test juga menjadi lebih gampang dihapus dan dibuat ulang dari nol kapan aja tanpa was-was ganggu data di proyek_dev.

**2. Pilih satu kebutuhan yang memiliki aturan paling rumit. Menurut kelompok kalian, apakah aturan tersebut lebih tepat ditegakkan menggunakan constraint, trigger, atau kode aplikasi? Berikan satu alasan.**

> Kebutuhan yang aturannya paling rumit menurut kami adalah soal unit alat yang sedang dalam status perbaikan tidak boleh dipinjamkan. Ini lebih cocok ditegakkan pakai trigger atau kode aplikasi, bukan constraint biasa, karena constraint semacam CHECK cuma bisa ngecek nilai di baris yang sama, sedangkan aturan ini butuh ngecek status unit_alat dari tabel lain pada saat baris peminjaman baru dibuat.

**3. Mengapa Peminjaman dan Unit Alat pada contoh tidak dihubungkan langsung, tetapi melalui Baris Pinjam? Apa yang hilang jika hubungan dibuat langsung?**

> Peminjaman dan Unit Alat tidak dihubungkan langsung karena satu transaksi peminjaman bisa aja mencakup lebih dari satu unit alat sekaligus. Kalau dihubungkan langsung (satu peminjaman cuma nunjuk satu unit_alat), kita bakal kehilangan kemampuan buat mencatat peminjaman yang isinya lebih dari satu alat dalam satu transaksi, jadi harus ada Baris Pinjam sebagai penghubung supaya tiap unit yang dipinjam di satu transaksi bisa dicatat sebagai baris terpisah.

**4. Apa perbedaan antara entitas Alat dan Unit Alat? Sebutkan satu pertanyaan bisnis yang hanya dapat dijawab jika keduanya dipisahkan.**

> Alat itu semacam jenis atau kategori barangnya, misalnya "Multimeter Digital", sedangkan Unit Alat itu barang fisiknya masing-masing yang punya kode/nomor unit sendiri dan bisa dilacak kondisinya satu-satu. Pertanyaan bisnis yang cuma bisa dijawab kalau dua ini dipisah misalnya "dari 10 unit Multimeter Digital yang kita punya, berapa yang lagi rusak dan berapa yang tersedia sekarang?" kalau cuma ada entitas Alat tanpa Unit Alat, kita gak bisa lacak kondisi tiap unit secara individual.

**5. Seorang anggota kelompok mengubah isi V1\_\_skema_awal.sql setelah migration tersebut sudah diterapkan, kemudian melakukan push ke repositori. Apa yang terjadi ketika anggota lain menjalankan migration? Jelaskan penyebab error dan cara memperbaikinya tanpa menghapus riwayat migration.**

> Anggota lain akan kena error checksum mismatch pas jalanin migration, soalnya Flyway nyimpen checksum dari isi V1 pas pertama kali diterapkan, dan begitu isi filenya diubah, checksum yang baru gak bakal cocok lagi sama yang tersimpan di flyway_schema_history. Cara benerinnya tanpa hapus riwayat adalah balikin isi V1 seperti semula (persis kayak yang udah diterapkan), terus kalau memang ada perubahan yang mau dilakukan, taruh di migration baru (versi berikutnya), bukan ngedit file yang udah pernah dijalankan.

**6. Catat apa yang terlihat pada pg_stat_activity. Perintah mana yang menunggu? Apa akibatnya jika kondisi tersebut terjadi pada basis data produksi saat banyak pengguna sedang mengakses sistem?**

> Yang keliatan di pg_stat_activity nanti adalah proses dari Terminal 2 (yang jalanin ALTER TABLE) berstatus active tapi wait_event_type-nya Lock, alias dia lagi nunggu. Ini karena Terminal 1 masih megang transaksi yang belum di-commit (walaupun cuma SELECT), dan ALTER TABLE butuh lock eksklusif ke seluruh tabel jadi harus nunggu transaksi itu selesai dulu. Kalau ini kejadian di database produksi yang lagi rame dipake, dampaknya bisa parah karena bukan cuma ALTER TABLE-nya yang nunggu, tapi query-query lain ke tabel yang sama juga bisa ikut ngantre di belakangnya, sampai transaksi yang nyangkut di awal itu di-commit atau rollback — istilahnya seluruh sistem bisa kayak "hang" sesaat.

**7. Mengapa seed data tidak diletakkan langsung di dalam migrations/? Sebutkan satu perbedaan sifat antara migration dan seed data.**

> Seed data gak ditaruh di migrations/ karena sifatnya beda. Migration itu perubahan struktur yang sifatnya historis dan gak boleh diubah lagi begitu diterapkan, sedangkan seed data itu data referensi/contoh yang wajar kalau sewaktu-waktu perlu diperbarui isinya tanpa harus nambah versi migration baru tiap kali. Makanya seed data ditaruh di folder terpisah dan dibikin idempoten pakai ON CONFLICT, biar bisa dijalankan ulang kapan aja tanpa bikin data ganda.

---

### Tautan Repositori Git Tim

https://github.com/elittaaasnrt-creator/TUGAS-MSBD-KELOMPOK4

---

### Daftar Commit Masing-Masing Anggota

| Anggota                    | Commit |
| -------------------------- | ------ |
| Jelita Hati Sinurat        | otw    |
| M. Ismail Dzakwan Rangkuti | otw    |
| Agi Aginta Sembiring       | otw    |
| M. Azkha Amorie            | otw    |
| Syifa Nazira               | otw    |
