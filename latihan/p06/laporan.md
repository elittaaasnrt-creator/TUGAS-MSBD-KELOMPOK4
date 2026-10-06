@'

# Laporan Latihan Kelompok Pertemuan 6

Manajemen Sistem Basis Data, Kelompok 4. Mengukur Harga Sebuah Index.

## Identitas Kelompok dan Kontribusi Commit

| Anggota                    | NIM       | GitHub                | Bagian                  | Commit           |
| -------------------------- | --------- | --------------------- | ----------------------- | ---------------- |
| Jelita Hati Sinurat        | 251402141 | elittaaasnrt-creator  | q00, Q1-Q6, Q31, README | 23cff18, d1cef82 |
| M. Ismail Dzakwan Rangkuti | 251402014 | dzakwanrangkuti       | Q7-Q11, Q27             |                  |
| Agi Aginta Sembiring       | 251402059 | agisembiring263-pixel | Q12-Q16, Q28            |                  |
| M. Azkha Amorie            | 251402092 | azkhaamorie           | Q17-Q21, Q29            |                  |
| Syifa Nazira               | 251402126 | ziraa94               | Q22-Q26, Q30            |                  |

Tautan merge request: (diisi setelah semua branch digabung)

## Kondisi Uji

- PostgreSQL 17 (Docker, image postgres:17, container msbd-pg)
- Mesin: laptop Intel Core i5-13420H (12 thread), RAM 16 GB, Windows
- Sumber daya Docker: 12 CPU, sekitar 8 GB RAM
- Data: lab6.event_log, 2.000.000 baris (tidak diturunkan)
- Setelan paralel: max_parallel_workers_per_gather = 0 pada sesi ukur
- Pengulangan: setiap query dijalankan 3 kali, dilaporkan tercepat dan median

## Q1-Q31

### Q1 (Reflektif)

Tabel lab6.event_log berukuran total 501 MB: heap 458 MB dan index 43 MB (hanya index primary key). Rata-rata ukuran per baris adalah 239,9 byte di heap dan 262,4 byte jika index ikut dihitung. Isi data per tuple (pg_column_size) rata-rata 226,0 byte. Perkiraan dari definisi kolom, yaitu header tuple 24 byte, kolom lebar tetap 36 byte, kolom teks pendek sekitar 53 byte, jumlah sekitar 7 byte, tags sekitar 41 byte, dan payload jsonb sekitar 60-70 byte, memberi total sekitar 215-225 byte, sangat dekat dengan hasil ukur 226 byte. Selisih dari 226 ke 239,9 byte berasal dari item pointer 4 byte per tuple, padding alignment tuple ke kelipatan 8 byte, header halaman, dan sisa ruang kosong di tiap halaman 8 KB.

### Q2

Tabel menempati 58.568 halaman heap dengan rata-rata 34,15 tuple per halaman (minimum 29, maksimum 35). Batas teoretis 291 tuple per halaman hanya tercapai jika tuple tidak berisi data: (8192 - 24) / (24 + 4) = 291. Tuple sebenarnya sekitar 226 byte data ditambah item pointer dan padding, sehingga satu tuple memakan sekitar 240 byte (8192 / 34,15 = 239,9 byte, sama dengan Q1). Satu halaman hanya muat sekitar 34-35 tuple, sekitar 12% dari batas teoretis. Minimum 29 kemungkinan berasal dari halaman terakhir yang tidak penuh atau tuple yang sedikit lebih panjang.

### Q3

Kolom dengan attstorage x (extended) adalah status, wilayah, kota, email, tags, dan payload. Tidak ada kolom bernilai e (external). Kolom jumlah (numeric) bernilai m (main), sedangkan kolom lebar tetap (event*id, customer_id, terjadi_pada, idempotency_key) bernilai p (plain). Strategi x berarti nilai besar boleh dikompresi lalu dipindahkan ke tabel TOAST, yang baru terjadi jika tuple melebihi sekitar 2 KB. Satu tuple di sini hanya sekitar 226 byte, sehingga ukuran tabel TOAST 0 bytes. Akibatnya SELECT * pada tabel ini tidak menanggung biaya tambahan. Pada tabel dengan kolom besar, SELECT \_ harus mengambil dan mendekompresi nilai dari tabel TOAST, sedangkan query yang hanya memilih kolom sempit tidak perlu menyentuhnya.

### Q4

Setelah UPDATE 10.000 baris pada kolom catatan (tidak terindeks), hot_longgar (fillfactor 80) mencatat n_tup_hot_upd 10.000 dari 10.000 (100%), sedangkan hot_penuh (fillfactor 100) mencatat 0 dari 10.000 (0%). HOT update hanya terjadi jika tidak ada kolom terindeks yang berubah dan versi baru baris muat di halaman heap yang sama. Syarat pertama terpenuhi di kedua tabel. Syarat kedua hanya terpenuhi di hot_longgar karena 20% tiap halamannya dikosongkan. Di hot_penuh versi baru harus ditulis di halaman lain dan semua index ikut menerima entri baru.

### Q5

Sebelum UPDATE, hot_longgar berukuran 676 halaman (5408 kB) dan hot_penuh 541 halaman (4328 kB), sehingga fillfactor 80 membuat tabel 25% lebih besar sejak awal. Setelah UPDATE, hot_longgar tetap 676 halaman, sedangkan hot_penuh tumbuh menjadi 595 halaman (4760 kB), bertambah 54 halaman (sekitar 10%). Selisih mengecil dari 25% menjadi sekitar 13,6%, tetapi hot_longgar masih lebih besar 648 kB. Itulah harga fillfactor: ruang disk dibayar di awal demi peluang HOT update yang menghindari penulisan ulang entri index dan mengurangi beban VACUUM. Ukuran total index kedua tabel sama (4416 kB), tetapi ukuran index sebelum UPDATE tidak diukur sehingga pertumbuhannya tidak dapat disimpulkan.

### Q6 (Reflektif)

Pada hot_longgar, UPDATE kolom catatan (tidak terindeks) menghasilkan 10.000 HOT update dari 10.000 (100%). UPDATE kolom nilai (terindeks) pada 10.000 baris lain menghasilkan 0 HOT update: n_tup_upd naik menjadi 20.000 sedangkan n_tup_hot_upd tetap 10.000, sehingga persentase kumulatif 50%. Halaman, fillfactor, dan ruang kosong sama, jadi pembedanya hanya apakah kolom terindeks ikut berubah. HOT update bergantung pada entri index yang tetap menunjuk ke tuple lama, lalu rantai HOT di dalam halaman meneruskan ke versi barunya. Itu hanya valid jika nilai kunci index tidak berubah. Jika nilai berubah, index harus diberi entri baru untuk versi baru baris, yaitu update biasa dengan biaya tulis index tambahan. Q4 menunjukkan kolom tidak terindeks saja tidak cukup tanpa ruang di halaman (hot_penuh 0% HOT), dan Q6 menunjukkan ruang kosong saja tidak cukup jika kolom terindeks berubah.

### Q7-Q11

(diisi Mael)

### Q12-Q16

(diisi Agi)

### Q17-Q21

(diisi Azkha)

### Q22-Q26

(diisi Syifa)

### Q27-Q31

(Q27 Mael, Q28 Agi, Q29 Azkha, Q30 Syifa, Q31 Jelita)

## Tabel Perbandingan

| Query/index | Tercepat | Median | Buffers | Ukuran | Keputusan |
| ----------- | -------- | ------ | ------- | ------ | --------- |

## Rekomendasi Akhir

(diisi setelah Q27-Q30 selesai)

## Penggunaan AI dan Verifikasi

(diisi bersama, sebutkan alat AI yang dipakai, bagian yang dibantu, dan cara setiap angka serta jawaban diverifikasi ulang)
'@ | Set-Content latihan\p06\laporan.md -Encoding utf8

