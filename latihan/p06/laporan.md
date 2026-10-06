@'
# Laporan Latihan Kelompok Pertemuan 6

Manajemen Sistem Basis Data, Kelompok 4. Mengukur Harga Sebuah Index.

## Identitas Kelompok dan Kontribusi Commit

| Anggota | NIM | GitHub | Bagian | Commit |
|---|---|---|---|---|
| Jelita Hati Sinurat | 251402141 | elittaaasnrt-creator | Q00, Q1-Q6, Q31, README | [43cf833](https://github.com/elittaaasnrt-creator/TUGAS-MSBD-KELOMPOK4/commit/43cf833), [a3acca4](https://github.com/elittaaasnrt-creator/TUGAS-MSBD-KELOMPOK4/commit/a3acca4), [2c05a57](https://github.com/elittaaasnrt-creator/TUGAS-MSBD-KELOMPOK4/commit/2c05a57) |
| M. Dzakwan Ismail Rangkuti | 251402014 | dzakwanrangkuti | Q7-Q11, Q27 | [9a7becd](https://github.com/elittaaasnrt-creator/TUGAS-MSBD-KELOMPOK4/commit/9a7becd) |
| M. Agita Sembiring | 251402059 | agisembiring263-pixel | Q12-Q16, Q28 | [c9cc960](https://github.com/elittaaasnrt-creator/TUGAS-MSBD-KELOMPOK4/commit/c9cc960) |
| M. Azzkha Amorie | 251402092 | azkhaamorie | Q17-Q21, Q29 | [04a6346](https://github.com/elittaaasnrt-creator/TUGAS-MSBD-KELOMPOK4/commit/04a6346) |
| Syifa Nazira | 251402126 | ziraa94 | Q22-Q26, Q30 | [903ac77](https://github.com/elittaaasnrt-creator/TUGAS-MSBD-KELOMPOK4/commit/903ac77) |

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
Tabel `lab6.event_log` berukuran total **501 MB**: heap 458 MB dan index 43 MB (hanya index primary key). Rata-rata ukuran per baris adalah 239,9 byte di heap dan 262,4 byte jika index ikut dihitung. Isi data per tuple (`pg_column_size`) rata-rata 226,0 byte. Perkiraan dari definisi kolom, yaitu header tuple 24 byte, kolom lebar tetap 36 byte, kolom teks pendek sekitar 53 byte, jumlah sekitar 7 byte, tags sekitar 41 byte, dan payload jsonb sekitar 60-70 byte, memberi total sekitar 215-225 byte, sangat dekat dengan hasil ukur 226 byte. Selisih dari 226 ke 239,9 byte berasal dari item pointer 4 byte per tuple, padding alignment tuple ke kelipatan 8 byte, header halaman, dan sisa ruang kosong di tiap halaman 8 KB.

---

### Q2
Tabel menempati **58.568 halaman heap** dengan rata-rata 34,15 tuple per halaman (minimum 29, maksimum 35). Batas teoretis 291 tuple per halaman hanya tercapai jika tuple tidak berisi data: `(8192 - 24) / (24 + 4) = 291`. Tuple sebenarnya sekitar 226 byte data ditambah item pointer dan padding, sehingga satu tuple memakan sekitar 240 byte (`8192 / 34,15 = 239,9 byte`, sama dengan Q1). Satu halaman hanya muat sekitar 34-35 tuple, sekitar **12%** dari batas teoretis. Minimum 29 kemungkinan berasal dari halaman terakhir yang tidak penuh atau tuple yang sedikit lebih panjang.

---

### Q3
Kolom dengan `attstorage` `x` (*extended*) adalah status, wilayah, kota, email, tags, dan payload. Tidak ada kolom bernilai `e` (*external*). Kolom jumlah (`numeric`) bernilai `m` (*main*), sedangkan kolom lebar tetap (`event_id`, `customer_id`, `terjadi_pada`, `idempotency_key`) bernilai `p` (*plain*). Strategi `x` berarti nilai besar boleh dikompresi lalu dipindahkan ke tabel TOAST, yang baru terjadi jika tuple melebihi sekitar 2 KB. Satu tuple di sini hanya sekitar 226 byte, sehingga ukuran tabel TOAST **0 bytes**. Akibatnya `SELECT *` pada tabel ini tidak menanggung biaya tambahan. Pada tabel dengan kolom besar, `SELECT *` harus mengambil dan mendekompresi nilai dari tabel TOAST, sedangkan query yang hanya memilih kolom sempit tidak perlu menyentuhnya.

---

### Q4
Setelah **UPDATE 10.000 baris** pada kolom `catatan` (tidak terindeks), `hot_longgar` (fillfactor 80) mencatat `n_tup_hot_upd` 10.000 dari 10.000 (**100%**), sedangkan `hot_penuh` (fillfactor 100) mencatat 0 dari 10.000 (**0%**). HOT update hanya terjadi jika tidak ada kolom terindeks yang berubah dan versi baru baris muat di halaman heap yang sama. Syarat pertama terpenuhi di kedua tabel. Syarat kedua hanya terpenuhi di `hot_longgar` karena 20% tiap halamannya dikosongkan. Di `hot_penuh` versi baru harus ditulis di halaman lain dan semua index ikut menerima entri baru.

---

### Q5
Sebelum UPDATE, `hot_longgar` berukuran **676 halaman** (5408 kB) dan `hot_penuh` **541 halaman** (4328 kB), sehingga fillfactor 80 membuat tabel **25% lebih besar** sejak awal. Setelah UPDATE, `hot_longgar` tetap 676 halaman, sedangkan `hot_penuh` tumbuh menjadi **595 halaman** (4760 kB), bertambah 54 halaman (sekitar 10%). Selisih mengecil dari 25% menjadi sekitar **13,6%**, tetapi `hot_longgar` masih lebih besar 648 kB. Itulah harga fillfactor: ruang disk dibayar di awal demi peluang HOT update yang menghindari penulisan ulang entri index dan mengurangi beban VACUUM. Ukuran total index kedua tabel sama (4416 kB), tetapi ukuran index sebelum UPDATE tidak diukur sehingga pertumbuhannya tidak dapat disimpulkan.

---

### Q6 (Reflektif)
Pada `hot_longgar`, UPDATE kolom `catatan` (tidak terindeks) menghasilkan **10.000 HOT update dari 10.000 (100%)**. UPDATE kolom `nilai` (terindeks) pada 10.000 baris lain menghasilkan **0 HOT update**: `n_tup_upd` naik menjadi 20.000 sedangkan `n_tup_hot_upd` tetap 10.000, sehingga persentase kumulatif **50%**. Halaman, fillfactor, dan ruang kosong sama, jadi pembedanya hanya apakah kolom terindeks ikut berubah. HOT update bergantung pada entri index yang tetap menunjuk ke tuple lama, lalu rantai HOT di dalam halaman meneruskan ke versi barunya. Itu hanya valid jika nilai kunci index tidak berubah. Jika nilai berubah, index harus diberi entri baru untuk versi baru baris, yaitu update biasa dengan biaya tulis index tambahan. Q4 menunjukkan kolom tidak terindeks saja tidak cukup tanpa ruang di halaman (`hot_penuh` 0% HOT), dan Q6 menunjukkan ruang kosong saja tidak cukup jika kolom terindeks berubah.

---

### Q7
Pada query baseline tanpa index tambahan (hanya primary key), planner menggunakan **Seq Scan** pada tabel `event_log` diikuti node **Sort** (`quicksort`) di memori untuk mengurutkan `terjadi_pada DESC` sebelum menerapkan node **Limit**. Estimasi baris planner (`rows=17`) sangat akurat dibandingkan dengan eksekusi nyata (`rows=16`). Total halaman memori/disk yang dibaca mencapai 58.569 blocks (`shared hit=14977 read=43592`). Pengujian menghasilkan waktu tercepat **102.11 ms** dan median **109.16 ms**.

---

### Q8
Ketika index `ev_salah_idx` (`terjadi_pada, customer_id`) dibuat, planner memilih **Index Scan Backward** pada index tersebut. Node `Sort` berhasil dihilangkan karena traversal index secara terbalik sudah menghasilkan urutan `terjadi_pada DESC`. Beban pembacaan buffer turun signifikan menjadi `3.827 blocks`. Namun, karena kolom `terjadi_pada` berada di posisi depan, PostgreSQL harus menelusuri rentang index berdasarkan filter waktu sembari memfilter `customer_id` satu per satu. Pengujian menghasilkan waktu tercepat **19.68 ms** dan median **22.79 ms**.

---

### Q9
Dengan index `ev_benar_idx` (`customer_id, terjadi_pada DESC`), pencarian menjadi jauh lebih optimal. Karena `customer_id` berada di posisi pertama, PostgreSQL dapat langsung melompat (*index lookup*) tepat ke grup `customer_id = 4211`. Dari sana, baris sudah otomatis terurut berdasarkan `terjadi_pada DESC`. Pengujian menghasilkan penurunan waktu eksekusi yang dramatis menjadi **0.060 ms** (tercepat) dan **0.065 ms** (median) dengan pembacaan buffer hanya **19 blocks**.

---

### Q10
Ukuran fisik kedua index pada disk adalah:
- Ukuran `ev_salah_idx`: **60 MB**
- Ukuran `ev_benar_idx`: **60 MB**

Kedua index memiliki ukuran yang sama persis karena menyimpannya pada tipe data dan jumlah tuple yang sama (`customer_id` berukuran 4 byte dan `terjadi_pada` berukuran 8 byte). Perbedaan performa antara Q8 dan Q9 murni disebabkan oleh **efisiensi penelusuran struktur B-Tree**, bukan karena perbedaan ukuran penyimpanan physical index.

---

### Q11 (Reflektif)
Aturan dasar pembuatan index gabungan adalah *Equality-First, Range/Sort-Second*. Pada `ev_benar_idx`, kolom dengan kondisi sama dengan (`customer_id = 4211`) diletakkan di depan. Daun B-Tree dikelompokkan berdasarkan `customer_id`, sehingga pencarian langsung menuju titik lokasi data tanpa memindai entri pelanggan lain. Selanjutnya, karena kolom kedua adalah `terjadi_pada DESC`, data di dalam grup pelanggan tersebut sudah terurut. Begitu optimizer mengambil 20 baris pertama, eksekusi langsung berhenti (*early stop*) tanpa perlu pembacaan berlebih maupun pemrosesan sorting tambahan di RAM.

---

### Q12
Pengukuran perbandingan ukuran antara partial index dan index polos pada kolom `terjadi_pada`:
- Ukuran index polos (`ev_polos_idx`): **43 MB**
- Ukuran partial index (`ev_gagal_idx`): **896 kB**
- **Penghematan Ukuran**: **~97,9%**. Partial index menghemat ruang disk dan RAM secara drastis karena hanya menyimpan entri untuk baris data yang memenuhi kondisi `WHERE status = 'GAGAL'`.

---

### Q13
Pengujian pencarian email dengan dan tanpa expression index:
- **Query `email = 'user100@contoh.ac.id'` (Tanpa Expression)**:
  * Node: `Parallel Seq Scan`
  * Execution Time: **532,803 ms**
  * Buffers: `shared hit=2268 read=56301` (total 58.569 blocks)
- **Query `lower(email) = 'user100@contoh.ac.id'` (Dengan Expression Index)**:
  * Node: `Bitmap Index Scan` menggunakan `ev_email_lower_idx`
  * Execution Time: **3,534 ms** (~150x lebih cepat)
  * Buffers: `shared read=4`

---

### Q14
Pengujian covering index `ev_cover_idx` sebelum dan sesudah perintah `VACUUM (ANALYZE)`:
- **Sebelum VACUUM (ANALYZE)**:
  * Node: `Index Only Scan` menggunakan `ev_cover_idx`
  * Heap Fetches: **0**
  * Buffers: `shared hit=2 read=4`
  * Execution Time: **3,480 ms**
- **Sesudah VACUUM (ANALYZE)**:
  * Node: `Index Only Scan` menggunakan `ev_cover_idx`
  * Heap Fetches: **0**
  * Buffers: `shared hit=6` (100% RAM hit)
  * Execution Time: **0,073 ms** (~47x lebih cepat)

---

### Q15
Perbandingan antara covering index (`INCLUDE`) dengan composite index 3 kolom biasa:
- Ukuran `ev_cover_idx` (`customer_id` INCLUDE `terjadi_pada, jumlah`): **77 MB**
- Ukuran `ev_3kolom_idx` (`customer_id, terjadi_pada, jumlah`): **77 MB**
- Rencana eksekusi kedua index sama-sama menghasilkan `Index Only Scan` dengan `Heap Fetches: 0`. Penggunaan klausa `INCLUDE` memberikan keuntungan arsitektural karena kolom tambahan hanya ditempatkan di *leaf node* tanpa menambah kompleksitas pengurutan internal node B-Tree.

---

### Q16 (Reflektif)
`Heap Fetches` bernilai 0 pada `Index Only Scan` menandakan bahwa PostgreSQL berhasil mengambil seluruh kolom data yang dibutuhkan query langsung dari struktur index tanpa perlu mengunjungi halaman tabel utama (*heap*). Perintah `VACUUM` memperbarui *Visibility Map* (VM) pada database; ketika seluruh tuple pada suatu halaman ditandai *all-visible* di VM, PostgreSQL tidak perlu lagi mengakses heap untuk memverifikasi visibilitas MVCC (*Multi-Version Concurrency Control*), sehingga menurunkan waktu eksekusi query secara signifikan.

---

### Q17 — GIN untuk JSONB (payload @> '{"promo": true}')

GIN (`ev_payload_gin_idx`, opclass `jsonb_path_ops`) dipakai lewat `Bitmap Index Scan`. Waktu: tercepat 267,9 ms, median 296,6 ms (3x uji: 438,3 / 296,6 / 267,9 ms). Ukuran index 7096 kB vs heap 458 MB — index hanya ±1,5% dari ukuran heap.


### Q18 — GIN untuk array (tags @>)

Dengan GIN (`ev_tags_gin_idx`): tercepat 255,0 ms, median 288,3 ms (313,3 / 288,3 / 255,0 ms). Tanpa GIN (dipaksa `enable_bitmapscan/indexscan = off`, jadi Seq Scan): 430,8 ms. GIN sekitar 1,5x lebih cepat.


### Q19 — Correlation dan ukuran BRIN vs B-Tree

`correlation` kolom `terjadi_pada` = **1** (sempurna), karena data di-insert berurutan waktu. Ukuran: BRIN 32 kB vs B-Tree 43 MB — BRIN lebih dari 1000x lebih kecil.

### Q20 — Rentang 7 hari: BRIN vs B-Tree

| Index | Tercepat | Median | Buffers |
|---|---:|---:|---:|
| BRIN | 7,35 ms | 7,90 ms | ~1414 |
| B-Tree | 8,76 ms | 9,69 ms | ~1499 |

BRIN menang baik di waktu maupun Buffers pada kondisi correlation tinggi ini, meski ukurannya 1000x lebih kecil dari B-Tree.

### Q29 — Daftar index lab6, idx_scan, ukuran

| Nama Index | idx_scan | Ukuran |
|---|---:|---:|
| ev_terjadi_brin_idx | 0 | 32 kB |
| event_log_pkey | 1 | 43 MB |
| ev_payload_gin_idx | 3 | 7096 kB |
| ev_tags_gin_idx | 3 | 4664 kB |

`ev_terjadi_brin_idx` tercatat idx_scan=0 karena index ini sempat di-drop dan dibuat ulang beberapa kali selama pengujian Q19–Q20 (untuk perbandingan head-to-head dengan B-Tree), sehingga statistik pemakaiannya ikut ter-reset. Index ini tetap layak dipertahankan: Q20 membuktikan BRIN menang di waktu dan Buffers dibanding B-Tree untuk query rentang waktu, dengan ukuran hanya 32 kB dibanding 43 MB.

## Reflektif Q21

Penghematan ukuran BRIN sepadan dengan selisih waktunya ketika kolom yang diindeks punya **correlation tinggi** terhadap urutan fisik tabel — pada percobaan kami, `correlation = 1` untuk `terjadi_pada` karena data di-insert berurutan waktu. Dalam kondisi ini BRIN tidak hanya jauh lebih kecil (32 kB vs 43 MB untuk B-Tree, hemat lebih dari 99%), tapi juga lebih cepat untuk query rentang (7,35 ms vs 8,76 ms tercepat, Buffers 1414 vs 1499). Sebaliknya, jika correlation rendah (data acak terhadap urutan fisik), BRIN akan membaca banyak block yang tidak relevan (lossy), dan B-Tree yang presisi per-baris akan menang meski ukurannya lebih besar.

---

### Q22
Pada pembuatan index `idx_event_status` di kolom status, rencana eksekusi menunjukkan perbedaan node scan yang signifikan. Kueri dengan kondisi `status = 'SUKSES'` menggunakan node **Seq Scan** pada tabel `event_log` dengan waktu eksekusi sekitar **324.95 ms** dan pembacaan buffer `shared hit=14886 read=43683`. Hal ini terjadi karena nilai `SUKSES` mencakup mayoritas data sebanyak 1.680.000 dari total 2.000.000 baris, sehingga optimizer menilai pemindaian sekuensial jauh lebih murah daripada pencarian acak di index. Sebaliknya, kueri dengan `status = 'GAGAL'` memilih **Index Scan using idx_event_status** dengan waktu eksekusi **149.20 ms** dan buffer `shared read=39974 written=16125` karena nilainya bersifat langka dan selektif hanya sebesar 40.000 baris.

---

### Q23
Perhitungan fraksi tiap status pada tabel `lab6.event_log` menghasilkan distribusi data sebesar **0.02** atau **2%** untuk status `GAGAL` (40.000 baris), **0.14** atau **14%** untuk status `TERTUNDA` (280.000 baris), dan **0.84** atau **84%** untuk status `SUKSES` (1.680.000 baris). Optimizer PostgreSQL umumnya berpindah dari `Index Scan` ke `Seq Scan` pada kisaran titik transisi selektivitas 10% hingga 15%. Pada nilai `SUKSES` yang mencapai 84%, overhead I/O akses acak melalui index jauh melampaui biaya membaca seluruh blok tabel secara sekuensial.

---

### Q24
Pengujian dengan menurunkan parameter `random_page_cost = 1.1` bertujuan untuk menekan estimasi biaya pembacaan acak pada index. Meskipun parameter diset mendekati harga `seq_page_cost` (1.0), kueri untuk `status = 'SUKSES'` tetap mempertahankan opsi **Seq Scan** dengan waktu eksekusi **329.04 ms**. Hal ini membuktikan bahwa pada fraksi data yang sangat tinggi (84%), pembacaan sekuensial seluruh blok tabel secara linier tetap lebih efisien dibandingkan traversal index.

---

### Q25
Pengujian kueri berfilter kombinasi `wilayah = 'Sumatera Utara'` dan `kota = 'Medan'` dijalankan dengan membuat extended statistics `CREATE STATISTICS stat_wilayah_kota (dependencies, ndistinct)` lalu di-`ANALYZE`. Rencana eksekusi sebelum dan sesudah extended statistics sama-sama menjalankan **Parallel Seq Scan** dengan 2 worker dan waktu eksekusi berkisar antara **81.01 ms** hingga **92.86 ms**. Keberadaan extended statistics mencatat ketergantungan fungsional antar-kolom sehingga memperpresisi estimasi baris (*cardinality estimation*) pada query planner ketika memproses kueri multi-kolom yang saling terikat secara geografis.

---

### Q26 (Reflektif)
Titik peralihan antara `Index Scan` dan `Seq Scan` bukan merupakan angka persentase yang tetap karena PostgreSQL menggunakan *cost-based optimizer* yang menghitung estimasi biaya I/O dan CPU secara dinamis. Perhitungan biaya ini dipengaruhi oleh rasio parameter `random_page_cost` terhadap `seq_page_cost`, tingkat korelasi fisik urutan data pada disk (`pg_stats.correlation`), ukuran total tabel, serta persentase data yang sudah tersimpan di *buffer cache* RAM. Akibatnya, titik transisi akan selalu menyesuaikan dengan kondisi fisik penyimpanan dan karakteristik distribusi data, bukan berupa satu angka persentase yang kaku.

---

### Q27
Pengujian dampak penulisan (*write overhead*) dilakukan dengan memasukkan 200.000 baris data ke dua tabel terpisah:

- **Tabel tanpa index (`test_no_idx`)**: Membutuhkan waktu **813.58 ms** (~0.81 detik).
- **Tabel dengan 6 index (`test_with_idx`)**: Membutuhkan waktu **2.295.57 ms** (~2.30 detik).

Penambahan 6 index menyebabkan proses `INSERT` menjadi **2.82 kali lipat lebih lambat** (penurunan kecepatan ~182%). Hal ini terjadi karena setiap operasi penulisan tuple baru ke tabel utama (*heap page*) mewajibkan PostgreSQL untuk melakukan traversal B-Tree/GIN/BRIN dan memperbarui struktur daun (*leaf nodes*) di seluruh index yang terpasang.

---

### Q28
Perbandingan ukuran total tabel setelah pengujian `INSERT` 200.000 baris pada Q27:
- **Tabel Tanpa Index (`test_no_idx`)**: **28 MB** (murni hanya ukuran data *heap*).
- **Tabel Dengan 5 Index (`test_with_idx`)**: **72 MB** (terdapat tambahan overhead sebesar 44 MB untuk mempertahankan seluruh struktur B-Tree index).

---

### Q30
Berdasarkan hasil pengujian seluruh kueri, index yang dipertahankan adalah `ev_benar_idx` (`customer_id, terjadi_pada DESC`) karena terbukti memangkas waktu eksekusi secara drastis serta menghilangkan node `Sort`, dan `ev_cover_idx` (`customer_id` INCLUDE `terjadi_pada, jumlah`) untuk mendukung `Index-Only Scan` tanpa *heap fetches*. Sebaliknya, index `idx_event_status` (`status`) direkomendasikan untuk dihapus karena memiliki `idx_scan = 0` pada kueri utama, bernilai selektivitas buruk untuk data dominan (84% `SUKSES`), serta memperlambat penulisan `INSERT`. Selain itu, index tunggal terpisah seperti `customer_id` dan `terjadi_pada` digabungkan menjadi satu *composite index* berpenutup (`INCLUDE`) guna menghemat ruang disk dan meningkatkan efisiensi kueri.

---

### Q31 (Reflektif)
Dalam menetapkan angka dasar keputusan untuk merekomendasikan apakah suatu index dipertahankan atau dihapus, indikator utama yang digunakan adalah nilai `idx_scan` dari `pg_stat_user_indexes` yang dikombinasikan dengan persentase penurunan waktu eksekusi (`execution time`) serta rasio efisiensi buffer. Sebagai contoh, index `ev_benar_idx` dipertahankan karena memberikan pemangkasan waktu eksekusi lebih dari 99% (dari ~102 ms menjadi 0.06 ms) dengan pembacaan buffer yang sangat minim (hanya 19 blocks). Sebaliknya, index `idx_event_status` direkomendasikan untuk dihapus karena memiliki nilai `idx_scan = 0` pada kueri utama, bernilai selektivitas buruk untuk data dominan (84% status SUKSES), serta terbukti menambah *overhead* penulisan pada operasi `INSERT` hingga 2.82 kali lipat lebih lambat.

---

## Tabel Perbandingan

| Query/index | Tercepat | Median | Buffers | Ukuran | Keputusan |
| ----------- | -------- | ------ | ------- | ------ | --------- |
| Q7 (Baseline - Tanpa Index) | 102.11 ms | 109.16 ms | hit=14977, read=43592 | 0 MB | Query lambat, butuh index gabungan |
| Q8 (`ev_salah_idx`) | 19.68 ms | 22.79 ms | hit=3827, read=0 | 60 MB | Lebih baik dari baseline, tapi urutan kolom belum optimal |
| Q9 (`ev_benar_idx`) | 0.060 ms | 0.065 ms | hit=19, read=0 | 60 MB | **Sangat Direkomendasikan** (peningkatan kecepatan ~1680x) |
| Q12 (`ev_polos_idx` vs `ev_gagal_idx`) | - | - | - | 43 MB vs 896 kB | **Dipertahankan** (Partial Index hemat ruang 97,9%) |
| Q13 (`lower(email)`) | 3.534 ms | 3.534 ms | read=4 | 43 MB | **Sangat Direkomendasikan** (akselerasi query ~150x) |
| Q14 (`ev_cover_idx` sesudah VACUUM) | 0.033 ms | 0.073 ms | hit=6, read=0 | 77 MB | **Sangat Direkomendasikan** (Index-Only Scan, Heap Fetches 0) |
| Q15 (`ev_cover_idx` vs `ev_3kolom_idx`) | 0.125 ms | 0.185 ms | hit=2, read=4 | 77 MB vs 77 MB | **Pilih `ev_cover_idx`** (fleksibilitas struktur B-Tree) |
| Q22 (`status = 'SUKSES'`) | 324.95 ms | 324.95 ms | hit=14886, read=43683 | 43 MB | `Seq Scan` lebih efisien untuk nilai dominan (84%) |
| Q22 (`status = 'GAGAL'`) | 149.20 ms | 149.20 ms | read=39974, written=16125 | 43 MB | `Index Scan` bekerja baik pada nilai selektif (2%) |
| Q24 (`random_page_cost = 1.1`) | 329.04 ms | 329.04 ms | hit=16206, read=42363 | 43 MB | `Seq Scan` tetap dipertahankan pada fraksi data tinggi |
| Q25 (`stat_wilayah_kota`) | 81.01 ms | 92.86 ms | hit=16098, read=42471 | 0 MB (stat) | **Direkomendasikan** untuk presisi estimasi multi-kolom |
| Q27 (Insert 200k Tanpa Index) | 813.58 ms | 813.58 ms | - | - | Baseline kecepatan tulis tabel |
| Q27 (Insert 200k 6 Index) | 2295.57 ms | 2295.57 ms | - | - | Ada *write overhead* ~2.82x lebih lambat |

## Rekomendasi Akhir

Rekomendasi akhir pengindeksan basis data meliputi penerapan *Composite Index* beraturan *Equality-First, Range/Sort-Second* seperti `ev_benar_idx` serta penggunaan klausa `INCLUDE` (`ev_cover_idx`) pada kueri berfrekuensi tinggi untuk mencapai `Index-Only Scan`. Pembuatan B-Tree index polos pada kolom bernilai unik rendah seperti `status` harus dihindari karena PostgreSQL tetap memilih `Seq Scan` dan index hanya akan membebani operasi penulisan `INSERT`. Selain itu, pemanfaatan Partial Index terbukti ampuh menghemat ruang penyimpanan hingga 97.9% pada kondisi filter tertentu seperti `status = 'GAGAL'`, sementara Expression Index (`lower(email)`) direkomendasikan untuk mempercepat kueri pencarian teks *case-insensitive*.

## Penggunaan AI dan Verifikasi
### Jelita Hati Sinurat
Saya menggunakan AI assistant sebagai pendamping untuk menyusun perintah, mengatasi kendala teknis, dan merapikan jawaban serta berkas laporan. Semua query saya jalankan sendiri, dan seluruh angka berasal dari keluaran terminal saya. Hasilnya saya verifikasi dengan mencocokkan antar-angka, misalnya jumlah halaman x 8 KB dengan ukuran heap.

### M. Dzakwan Ismail Rangkuti
Saya menggunakan AI assistant sebagai teman diskusi untuk memverifikasi langkah-langkah `EXPLAIN (ANALYZE, BUFFERS)` di psql Docker, memandu sintaks pencatatan ukuran index, serta menganalisis hasil perbandingan performa. Seluruh eksekusi query saya lakukan secara mandiri di terminal lokal, dan semua data angka pada laporan ini diambil dari hasil run nyata di lingkungan sistem saya.

### Agi Aginta Sembiring
Saya menggunakan AI assistant untuk membantu merancang pengujian partial index, expression index, dan covering index pada PostgreSQL, serta memahami mekanisme Visibility Map saat `VACUUM`. Pengujian dilakukan secara mandiri di terminal `psql` lokal dan seluruh angka hasil pengukuran diverifikasi langsung dari output `EXPLAIN (ANALYZE, BUFFERS)`.

### Muhammad Azkha Amorie
Saya menggunakan AI assistant untuk membantu menyusun query GIN pada JSONB (`jsonb_path_ops`) dan array `tags`, memahami correlation serta trade-off ukuran-kecepatan BRIN dibanding B-Tree pada kolom waktu, serta menyusun query `pg_stat_user_indexes` untuk mendaftar pemakaian index (Q17–Q21, Q29, Reflektif Q21). Seluruh query saya jalankan sendiri di terminal, dan angka pada laporan diambil langsung dari keluaran `EXPLAIN (ANALYZE, BUFFERS)`.

### Syifa Nazira
Saya menggunakan AI assistant untuk mendiskusikan mekanisme selektivitas query, dampak perubahan `random_page_cost`, dan pembentukan extended statistics pada PostgreSQL. Seluruh eksekusi query dilakukan secara mandiri di terminal psql Docker lokal, dan seluruh data angka pada laporan ini diambil langsung dari keluaran `EXPLAIN (ANALYZE, BUFFERS)` nyata pada sistem saya.

'@ | Set-Content latihan\p06\laporan.md -Encoding utf8
