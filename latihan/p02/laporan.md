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

Kelompok kami pilih domain peminjaman alat laboratorium.

Alasannya karena batasannya jelas. Cuma nyangkut katalog alat, peminjaman, pengembalian, sama perbaikan alat aja. Gak perlu masuk-masuk ke sistem akademik atau keuangan kampus.

Tapi domain ini tetep punya aturan bisnis yang lumayan rumit buat dimodelin, contohnya:

- Kuota peminjaman : anggota gak bisa asal pinjam sebanyak-banyaknya, ada batas maksimal unit yang boleh dipinjam dalam satu waktu.
- Denda keterlambatan : kalau telat balikin dari jatuh tempo, kena denda, dan dendanya dihitung dari berapa lama telatnya.
- Alat yang lagi diperbaiki gak boleh dipinjamkan : jadi kalau statusnya "dalam perbaikan", unit itu otomatis gak boleh muncul sebagai unit yang tersedia.

Tiga aturan ini yang bikin kami mikir domain ini pas buat latihan, soalnya gak bisa diselesein cuma pakai tabel biasa doang, harus mikirin constraint, trigger, atau logic di aplikasi.

---

### Ringkasan Lingkup Sistem

TODO (rujuk `kebutuhan.md`)

---

### Ringkasan Kebutuhan Data

TODO (rujuk `kebutuhan.md`)

---

### Penjelasan ERD

TODO

Bukti: `erd.png`

---

### Status Migration

TODO

Bukti: `bukti/flyway-info.png`, `bukti/migration-history.png`

---

### Bukti Database Dapat Dibangun Ulang

TODO

Bukti: `bukti/rebuild-database.png`

---

### Pola Tiga Langkah Penambahan Kolom NOT NULL

TODO

---

### Eksperimen Locking dan Pengamatan pg_stat_activity

TODO

Bukti: `bukti/pg-stat-activity.png`

---

### Hasil Seed Data (dijalankan dua kali)

TODO

Bukti: `bukti/seed-data.png`

---

### Jawaban Pertanyaan 1–7

**1. Mengapa lingkungan pengujian memerlukan basis data sendiri, dan bukan sekadar schema terpisah di dalam basis data yang sama?**

> Lingkungan pengujian butuh basis data sendiri karena kita sering sengaja masukin data aneh atau data rusak buat nguji constraint dan aturan bisnis, jadi kalau cuma dipisah pakai schema doang, resikonya masih satu database yang sama dan bisa aja kepengaruh kalau ada konfigurasi yang salah. Selain itu proyek_test juga jadi lebih gampang dihapus dan dibuat ulang dari nol kapan aja tanpa was-was ganggu data di proyek_dev.

**2. Pilih satu kebutuhan yang memiliki aturan paling rumit. Menurut kelompok kalian, apakah aturan tersebut lebih tepat ditegakkan menggunakan constraint, trigger, atau kode aplikasi? Berikan satu alasan.**

> Kebutuhan yang aturannya paling rumit menurut kami adalah soal unit alat yang sedang dalam status perbaikan tidak boleh dipinjamkan. Ini lebih cocok ditegakkan pakai trigger atau kode aplikasi, bukan constraint biasa, karena constraint semacam CHECK cuma bisa ngecek nilai di baris yang sama, sedangkan aturan ini butuh ngecek status unit_alat dari tabel lain pada saat baris peminjaman baru dibuat.

**3. Mengapa Peminjaman dan Unit Alat pada contoh tidak dihubungkan langsung, tetapi melalui Baris Pinjam? Apa yang hilang jika hubungan dibuat langsung?**

> Peminjaman dan Unit Alat gak dihubungkan langsung karena satu transaksi peminjaman bisa aja mencakup lebih dari satu unit alat sekaligus. Kalau dihubungkan langsung (satu peminjaman cuma nunjuk satu unit_alat), kita bakal kehilangan kemampuan buat mencatat peminjaman yang isinya lebih dari satu alat dalam satu transaksi, jadi harus ada Baris Pinjam sebagai penghubung supaya tiap unit yang dipinjam di satu transaksi bisa dicatat sebagai baris terpisah.

**4. Apa perbedaan antara entitas Alat dan Unit Alat? Sebutkan satu pertanyaan bisnis yang hanya dapat dijawab jika keduanya dipisahkan.**

> Alat itu semacam jenis atau kategori barangnya, misalnya "Multimeter Digital", sedangkan Unit Alat itu barang fisiknya masing-masing yang punya kode/nomor unit sendiri dan bisa dilacak kondisinya satu-satu. Pertanyaan bisnis yang cuma bisa dijawab kalau dua ini dipisah misalnya "dari 10 unit Multimeter Digital yang kita punya, berapa yang lagi rusak dan berapa yang tersedia sekarang?" — kalau cuma ada entitas Alat tanpa Unit Alat, kita gak bisa lacak kondisi tiap unit secara individual.

**5. Seorang anggota kelompok mengubah isi V1\_\_skema_awal.sql setelah migration tersebut sudah diterapkan, kemudian melakukan push ke repositori. Apa yang terjadi ketika anggota lain menjalankan migration? Jelaskan penyebab error dan cara memperbaikinya tanpa menghapus riwayat migration.**

> Anggota lain bakal kena error checksum mismatch pas jalanin migration, soalnya Flyway nyimpen checksum dari isi V1 pas pertama kali diterapkan, dan begitu isi filenya diubah, checksum yang baru gak bakal cocok lagi sama yang tersimpan di flyway_schema_history. Cara benerinnya tanpa hapus riwayat adalah balikin isi V1 seperti semula (persis kayak yang udah diterapkan), terus kalau memang ada perubahan yang mau dilakukan, taruh di migration baru (versi berikutnya), bukan ngedit file yang udah pernah dijalankan.

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
