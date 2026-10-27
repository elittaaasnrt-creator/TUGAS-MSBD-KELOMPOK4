# Laporan Latihan P09 - Menguji Transaksi dan Kendali Konkurensi

**Mata kuliah:** Manajemen Sistem Basis Data · **Kelompok 4**
**Cabang:** `latihan/p09-transaksi-konkurensi`

---

## 1. Lingkungan Percobaan

_(bagian: Azkha)_

| Item                                | Nilai                                                                                   |
| ----------------------------------- | --------------------------------------------------------------------------------------- |
| Versi PostgreSQL                    | PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2) on x86_64-pc-linux-gnu                       |
| Alat                                | psql di dalam container Docker (`msbd-pg`), dua terminal PowerShell (Sesi A dan Sesi B) |
| Database / skema                    | `pagila` / `lab9`                                                                       |
| transaction_isolation (default)     | read committed                                                                          |
| deadlock_timeout                    | 1s                                                                                      |
| lock_timeout                        | 0 (nonaktif)                                                                            |
| statement_timeout                   | 0 (nonaktif)                                                                            |
| idle_in_transaction_session_timeout | 0 (nonaktif)                                                                            |

Data awal (`q00_setup.sql`): `lab9.rekening` berisi Ani (id 1) dan Budi (id 2), masing-masing saldo 1.000.000,00.

Format jawaban tiap soal: **Urutan operasi (Sesi A / Sesi B)** → **Hasil (sebelum/sesudah, COMMIT/ROLLBACK, SQLSTATE)** → **Penjelasan penyebab**.

---

## 2. Jawaban Q1-Q32

### Langkah 1 · Setup dan Batas Transaksi (Jelita)

#### Q1. Kondisi awal dan total saldo

Urutan: Sesi A menjalankan `SELECT * FROM lab9.rekening ORDER BY rekening_id;` dan `SELECT SUM(saldo) ...`.

| rekening_id | pemilik | saldo        |
| ----------- | ------- | ------------ |
| 1           | Ani     | 1.000.000,00 |
| 2           | Budi    | 1.000.000,00 |

Total saldo = **2.000.000,00**. Total ini menjadi acuan: ROLLBACK atau error seharusnya tidak mengubah jumlahnya.

#### Q2. Perubahan sebelum COMMIT

Urutan:

1. Sesi A: `BEGIN;` lalu `UPDATE ... SET saldo = saldo - 100000 WHERE rekening_id = 1;`
2. Sesi A: `SELECT` menunjukkan Ani **900.000**.
3. Sesi B: `SELECT` menunjukkan Ani masih **1.000.000**.

Penjelasan: perubahan di dalam transaksi yang belum di-COMMIT hanya terlihat oleh sesi pemiliknya. Sesi lain tetap membaca versi data yang sudah di-commit (READ COMMITTED), jadi tidak ada dirty read. Ini perwujudan _isolation_ pada ACID.

#### Q3. COMMIT vs ROLLBACK

| Skenario | Hasil di Sesi A                | Hasil sesudahnya                           | Status            |
| -------- | ------------------------------ | ------------------------------------------ | ----------------- |
| COMMIT   | Ani 900.000                    | Sesi B melihat Ani **900.000**             | Bertahan permanen |
| ROLLBACK | Ani 900.000 di dalam transaksi | Setelah ROLLBACK Ani kembali **1.000.000** | Dibatalkan        |

Hanya perubahan yang di-**COMMIT** yang bertahan. Pada skenario ROLLBACK, data direset dulu dengan `q00_setup.sql` supaya titik awalnya sama.

#### Q4. SAVEPOINT

Urutan di Sesi A:

1. `BEGIN;` lalu update Ani -100.000 (Ani 900.000).
2. `SAVEPOINT sp1;`
3. Update Budi -200.000 (Budi 800.000).
4. `ROLLBACK TO SAVEPOINT sp1;` lalu Budi kembali **1.000.000**, Ani tetap **900.000**.
5. `COMMIT;` dan hasil akhir Ani 900.000, Budi 1.000.000.

Penjelasan: `ROLLBACK TO SAVEPOINT` hanya membatalkan perubahan yang dibuat **setelah** savepoint (update Budi). Update sebelum savepoint (Ani) tetap berada di transaksi dan ikut tersimpan saat COMMIT.

#### Q5. Atomicity dan consistency

Urutan di Sesi A:

1. `BEGIN;`
2. Update Ani -100.000: berhasil (`UPDATE 1`).
3. Update Budi -99.999.999: **gagal**, `ERROR 23514` (`rekening_saldo_check`, baris gagal berisi saldo -98.999.999,00).
4. `SELECT` berikutnya ditolak dengan `ERROR 25P02` (current transaction is aborted).
5. `ROLLBACK;` dan hasilnya Ani **900.000** (bukan 800.000), Budi 1.000.000.

Penjelasan:

- **Atomicity**: transaksi bersifat semua-atau-tidak-sama-sekali. Update Ani yang valid ikut batal karena transaksinya gagal.
- **Consistency**: constraint `CHECK (saldo >= 0)` menolak perubahan yang membuat data tidak valid.
- Setelah error, transaksi berstatus _aborted_ (SQLSTATE 25P02), jadi satu-satunya jalan adalah `ROLLBACK`.

---

### Langkah 2 · Isolation Level dan Anomali (Mael)

#### Q6. Non-repeatable read (READ COMMITTED)

- **Urutan**:
  1. Sesi A: `BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;` lalu `SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;`
  2. Sesi B: `BEGIN; UPDATE lab9.rekening SET saldo = 1200000 WHERE rekening_id = 1; COMMIT;`
  3. Sesi A: `SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;` lalu `COMMIT;`
- **Hasil**: Pembacaan pertama di Sesi A bernilai **1.000.000,00**, sedangkan pembacaan kedua bernilai **1.200.000,00**.
- **Penjelasan**: Pada level `READ COMMITTED`, setiap statement query membaca snapshot data paling baru yang sudah ter-commit. Ketika Sesi B melakukan commit di sela transaksi Sesi A, Sesi A membaca baris yang sudah diubah tersebut sehingga terjadi anomali _Non-repeatable Read_.

#### Q7. Perbandingan dengan REPEATABLE READ

- **Urutan**:
  1. Sesi A: `BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;` lalu `SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;`
  2. Sesi B: `BEGIN; UPDATE lab9.rekening SET saldo = 1500000 WHERE rekening_id = 1; COMMIT;`
  3. Sesi A: `SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;` lalu `COMMIT;`
- **Hasil**: Pembacaan pertama bernilai **1.200.000,00** dan pembacaan kedua tetap bernilai **1.200.000,00**.
- **Penjelasan**: Tingkat isolasi `REPEATABLE READ` membekukan snapshot transaksi pada saat statement pembacaan pertama dijalankan. Pembaruan data oleh transaksi lain (Sesi B) tidak terlihat sampai transaksi Sesi A selesai.

#### Q8. Phantom read

- **Urutan**:
  - _READ COMMITTED_: Sesi A menjalankan `SELECT COUNT(*)`, Sesi B menjalankan `INSERT`, Sesi A mengulang `SELECT COUNT(*)`.
  - _REPEATABLE READ_: Sesi A menjalankan `SELECT COUNT(*)`, Sesi B menjalankan `INSERT`, Sesi A mengulang `SELECT COUNT(*)`.
- **Hasil (READ COMMITTED vs REPEATABLE READ)**:
  - Pada `READ COMMITTED`, jumlah baris bertambah dari **2** menjadi **3** (_Phantom Read_ terjadi).
  - Pada `REPEATABLE READ`, jumlah baris tetap konsisten di angka **3** (baris baru Doni tidak masuk ke snapshot).
- **Penjelasan**: Standar ANSI SQL menyatakan `REPEATABLE READ` memperbolehkan Phantom Read, namun implementasi MVCC PostgreSQL mencegahnya karena transaksi membaca snapshot tetap dari awal transaksi.

#### Q9. Dirty read dan READ UNCOMMITTED

- **Urutan**:
  1. Sesi A: `BEGIN; UPDATE lab9.rekening SET saldo = 9999999 WHERE rekening_id = 1;` (tanpa COMMIT).
  2. Sesi B: `BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; SELECT saldo FROM lab9.rekening WHERE rekening_id = 1; COMMIT;`
  3. Sesi A: `ROLLBACK;`
- **Hasil**: Sesi B membaca saldo **1.500.000,00** (data lama sebelum diubah Sesi A). Nilai 9.999.999 tidak pernah terlihat.
- **Penjelasan**: PostgreSQL tidak mendukung _Dirty Read_. Tingkat isolasi `READ UNCOMMITTED` secara internal diperlakukan sama persis dengan `READ COMMITTED` oleh engine MVCC.

#### Q10. Lost update

- **Urutan**:
  1. Sesi A dan Sesi B sama-sama membaca saldo awal Ani (1.000.000,00).
  2. Sesi A menghitung penambahan (+200.000) dan mengeksekusi `UPDATE ... SET saldo = 1200000; COMMIT;`
  3. Sesi B menghitung pengurangan (-100.000) dan mengeksekusi `UPDATE ... SET saldo = 900000; COMMIT;`
- **Hasil**: Saldo akhir bernilai **900.000,00**. Penambahan 200.000 dari Sesi A hilang tertimpa.
- **Penjelasan**: Menulis nilai absolut hasil kalkulasi lokal di aplikasi menyebabkan _Lost Update_ karena transaksi kedua tidak memperhitungkan pembaruan yang baru saja di-commit oleh transaksi pertama.

#### Q11. Tabel ringkas anomali

| Anomali                 | Urutan kejadian                                                                                       | Isolation level  | Hasil yang diamati                                                     | Cara mencegah/menangani                                                                  |
| ----------------------- | ----------------------------------------------------------------------------------------------------- | ---------------- | ---------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| **Dirty Read**          | Transaksi A mengubah baris tanpa commit, Transaksi B membaca baris tersebut.                          | READ UNCOMMITTED | Tidak terbaca (tetap membaca data lama).                               | Bawaan MVCC PostgreSQL (selalu dipetakan ke READ COMMITTED).                             |
| **Non-repeatable Read** | Transaksi A membaca, Transaksi B update + commit, Transaksi A membaca ulang baris yang sama.          | READ COMMITTED   | Nilai kolom berubah di tengah transaksi (1.000.000 -> 1.200.000).      | Gunakan `REPEATABLE READ`, `SERIALIZABLE`, atau `FOR SHARE`.                             |
| **Phantom Read**        | Transaksi A menghitung baris rentang, Transaksi B insert + commit, Transaksi A membaca ulang rentang. | READ COMMITTED   | Jumlah baris bertambah dari 2 menjadi 3.                               | Gunakan `REPEATABLE READ` atau `SERIALIZABLE`.                                           |
| **Lost Update**         | Dua transaksi membaca nilai yang sama, menghitung lokal, lalu menulis nilai statis berurutan.         | READ COMMITTED   | Pembaruan transaksi pertama tertimpa dan hilang (saldo akhir 900.000). | Gunakan pembaruan atomik (`SET saldo = saldo + n`), `FOR UPDATE`, atau versi optimistik. |

---

### Langkah 3 · Mencegah Lost Update dan MVCC (Agi)

#### Q12. Pembaruan atomik

- Urutan:
  Sesi A: BEGIN; UPDATE lab9.rekening SET saldo = saldo - 10000 WHERE rekening_id = 1 AND saldo >= 10000; COMMIT;
  Sesi B: perintah UPDATE yang sama (tanpa membaca saldo lebih dulu), lalu COMMIT;
- Hasil: Ani turun dari 1.000.000 ke 990.000 (setelah Sesi A) lalu 980.000,00 (setelah Sesi B, UPDATE 1, COMMIT). Kedua pengurangan tercatat. Tidak ada error.
- Penjelasan: saldo = saldo - 10000 dihitung oleh database terhadap nilai terbaru yang sudah di-commit, sehingga tidak bergantung pada nilai bacaan lama di aplikasi. Pada READ COMMITTED, UPDATE yang menemui baris yang sedang diubah transaksi lain menunggu transaksi itu selesai, lalu mengevaluasi ulang syarat WHERE pada versi terbaru. Berbeda dengan Q10 yang menulis nilai tetap hasil hitung lama (hasil akhir 900.000, setoran 200.000 hilang). Syarat AND saldo >= 10000 juga mencegah saldo negatif; jika saldo tidak cukup hasilnya UPDATE 0.

#### Q13. SELECT ... FOR UPDATE

- Urutan:
  Sesi A: BEGIN; SELECT saldo FROM lab9.rekening WHERE rekening_id = 1 FOR UPDATE;
  Sesi B: BEGIN; lalu SELECT yang sama. Sesi B menunggu selama A belum selesai.
  Sesi A: UPDATE ... SET saldo = 990000 WHERE rekening_id = 1; COMMIT;
  Sesi B: setelah A COMMIT, SELECT ... FOR UPDATE langsung menampilkan hasil, lalu UPDATE ... SET saldo = 980000; COMMIT;
- Hasil: Sesi B menampilkan saldo 990.000,00 (nilai yang di-commit A), bukan 1.000.000. Hasil akhir Ani 980.000,00. Lama menunggu B tidak tercetak di terminal.
- Penjelasan:FOR UPDATE mengunci baris sehingga sesi kedua antre, lalu membaca versi terbaru setelah kunci dilepas. Tidak ada lost update seperti Q10. Kompromi: sesi yang menunggu tertahan, dan jika kunci ditahan terlalu lama muncul antrean panjang (lihat Q22).

#### Q14. Optimistic locking (`version_no`)

- Urutan:
  Tabel dibuat ulang dengan kolom version_no INT NOT NULL DEFAULT 1; Ani 1000000.00 | 1.
  Sesi A dan B sama-sama membaca baris Ani (versi 1).
  Sesi A: UPDATE ... SET saldo = 990000, version_no = version_no + 1 WHERE rekening_id = 1 AND version_no = 1; menghasilkan UPDATE 1.
  Sesi B (masih memegang versi 1): perintah yang sama menghasilkan UPDATE 0.
  Sesi B membaca ulang (990000.00 | 2), lalu update dengan version_no = 2 menghasilkan UPDATE 1.
- Hasil: akhir Ani 980.000,00 | versi 3. Pembacaan awal Sesi B tidak tercetak di terminal.
- Penjelasan: UPDATE 0 adalah sinyal bagi aplikasi bahwa baris sudah diubah sesi lain sejak dibaca. Aplikasi lalu membaca ulang dan mengulang. Konflik terdeteksi, bukan dicegah; cocok untuk beban dengan konflik jarang dan tanpa menahan lock.

#### Q15. MVCC dan snapshot

- Urutan:
  Sesi A: BEGIN ISOLATION LEVEL REPEATABLE READ; lalu SELECT saldo ... menampilkan 980.000.
  Sesi B: BEGIN; UPDATE ... SET saldo = saldo - 5000 ...; SELECT di B menampilkan 975.000 (belum COMMIT).
  Sesi A: SELECT yang sama tetap 980.000 dan langsung muncul.
  Sesi B: COMMIT;
  Sesi A: SELECT masih 980.000,00; setelah COMMIT A, SELECT menjadi 975.000,00.
- Hasil: hasil langkah 5 tercatat di terminal; langkah 1-3 tidak tercetak (dijalankan sesuai urutan).
- Penjelasan: UPDATE tidak menimpa baris, melainkan membuat versi baru. Tiap transaksi membaca versi yang terlihat menurut snapshot-nya, sehingga pembaca tidak menunggu penulis dan penulis tidak menunggu pembaca. Snapshot A tetap sampai A selesai.

#### Q16. xmin dan xmax

- Hasil query: Hasil query (setelah ROLLBACK di Sesi A; Sesi B membaca hasil identik):
  rekening_id saldo xmin xmax
  1 975000.00 1116 1118
  Pembacaan awal (xmax = 0) dan hasil SELECT ... FOR UPDATE tidak tercetak di terminal.
- Penjelasan: xmin dan xmax adalah kolom sistem (metadata transaksi) pada setiap versi baris, bukan kolom bisnis. xmin adalah ID transaksi yang membuat versi baris (kemungkinan UPDATE Sesi B di Q15). xmax adalah ID transaksi yang menghapus, meng-update, atau mengunci versi tersebut. xmax = 1118 kemungkinan berasal dari SELECT ... FOR UPDATE Sesi A yang dibatalkan, sebab baris tidak dihapus dan saldo tetap 975.000 (hubungan ke transaksi A adalah kesimpulan, bukan hasil yang tercetak). Karena itu satu nilai xmin/xmax saja tidak cukup: PostgreSQL juga memeriksa status transaksi itu (commit atau abort) dan penanda lock internal untuk menentukan visibilitas.

#### Q17. Manfaat MVCC dan peran vacuum

- Hasil (pg_stat_user_tables): n_live_tup = 2, n_dead_tup = 6. Angka ini perkiraan statistik, bukan jumlah pasti.
- Penjelasan: manfaat MVCC adalah konkurensi tinggi, karena pembaca dan penulis tidak saling blokir (Q15). Harganya, setiap UPDATE/DELETE meninggalkan versi lama (dead tuple). Hasil di atas menunjukkan 2 baris hidup tetapi sekitar 6 versi lama yang menumpuk. Vacuum (otomatis lewat autovacuum atau manual) menandai ruang itu agar dapat dipakai ulang, memperbarui visibility map, dan mencegah bloat serta masalah transaction ID wraparound.

---

### Langkah 4 · Row Lock, Deadlock, dan Antrean Lock (Azkha)

#### Q18. FOR UPDATE / NO KEY UPDATE / SHARE / KEY SHARE

| Mode              | Tujuan umum                                                                                                        | Kapan transaksi lain terhalang                                                 |
| ----------------- | ------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------ |
| FOR UPDATE        | Kunci terkuat: mengunci baris untuk UPDATE/DELETE atau perubahan kolom kunci.                                      | Menghalangi semua mode lain (FOR UPDATE, NO KEY UPDATE, SHARE, KEY SHARE).     |
| FOR NO KEY UPDATE | Mengunci baris untuk UPDATE yang tidak mengubah kolom kunci (mode yang diambil UPDATE biasa).                      | Menghalangi FOR UPDATE, NO KEY UPDATE, dan SHARE; tidak menghalangi KEY SHARE. |
| FOR SHARE         | Kunci bersama: baris tidak boleh diubah atau dihapus selama dipegang, tetapi banyak sesi boleh memegang bersamaan. | Menghalangi FOR UPDATE dan NO KEY UPDATE; sesama SHARE dan KEY SHARE lolos.    |
| FOR KEY SHARE     | Kunci terlemah: menjaga kolom kunci tidak berubah dan baris tidak dihapus (dipakai pengecekan foreign key).        | Hanya menghalangi FOR UPDATE.                                                  |

#### Q19. Penguncian baris yang sama

- Urutan: [A] `BEGIN; SELECT ... WHERE rekening_id = 1 FOR UPDATE;` lalu [B] `BEGIN;` dan `SELECT` yang sama, lalu [A] `COMMIT;`, lalu [B] `COMMIT;`.
- Hasil: Sesi B menggantung (tanpa hasil dan tanpa prompt baru) selama A belum COMMIT. Setelah A COMMIT, B langsung mendapat baris Ani (saldo 1.000.000,00) tanpa error, lalu COMMIT.
- Penjelasan: FOR UPDATE bersifat eksklusif per baris. Sesi kedua antre sampai pemegang lock mengakhiri transaksinya.

#### Q20. Deadlock

- Urutan: [A] `BEGIN`, kunci id 1. [B] `BEGIN`, kunci id 2. [A] kunci id 2 (menunggu B). [B] kunci id 1 (menunggu A).
- Hasil (sesi yang kena, SQLSTATE 40P01): **Sesi B** (PID 392) menjadi korban: `ERROR: deadlock detected`, SQLSTATE **40P01**. Sesi A (PID 377) lolos dan mendapat baris id 2. Kedua sesi di-ROLLBACK.
- Penjelasan: A memegang id 1 dan menunggu id 2, B memegang id 2 dan menunggu id 1. Siklus saling tunggu ini tidak bisa selesai sendiri. PostgreSQL mendeteksinya setelah `deadlock_timeout` (1s) lalu membatalkan satu transaksi.

#### Q21. Urutan penguncian konsisten

- Urutan: [A] `BEGIN`, kunci id 1. [B] `BEGIN`, kunci id 1 (menggantung). [A] kunci id 2, `COMMIT`. [B] lanjut, kunci id 2, `COMMIT`.
- Hasil: tidak ada error 40P01. B menunggu A di baris id 1, lalu selesai normal setelah A COMMIT.
- Penjelasan: jika semua sesi mengunci dari id terkecil ke terbesar, tidak pernah terbentuk siklus tunggu. Deadlock pada skenario ini dapat dihindari.

#### Q22. Deadlock vs antrean lock panjang

- Contoh transaksi yang menahan lock terlalu lama: Sesi A `BEGIN` dan `SELECT ... WHERE rekening_id = 1 FOR UPDATE`, lalu dibiarkan tanpa COMMIT (status `idle in transaction`). Sesi B yang meminta baris yang sama antre.
- Hasil `pg_stat_activity` / `pg_locks`: PID 377 (A): `idle in transaction`, `ClientRead`, `diblokir_oleh = {}`. PID 392 (B): `active`, `wait_event_type = Lock`, `wait_event = transactionid`, `diblokir_oleh = {377}`. `pg_locks`: `transactionid | ShareLock | granted = f | pid 392`.
- Penjelasan: deadlock adalah siklus saling tunggu yang dideteksi otomatis lalu salah satu korban dibatalkan (40P01). Antrean lock panjang tidak punya siklus: penunggu hanya menunggu pemegang yang lambat, tanpa error otomatis, dan baru selesai jika pemegang COMMIT/ROLLBACK atau timeout terpasang.

#### Q23. Perbandingan timeout

| Parameter                           | Fungsi                                                                                 | Hasil uji                                                                                                            |
| ----------------------------------- | -------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| lock_timeout                        | Batas waktu menunggu lock; lewat batas, statement dibatalkan.                          | `SET LOCAL lock_timeout = '2s'`, B mengunci baris yang dipegang A: `ERROR: canceling statement due to lock timeout`. |
| statement_timeout                   | Batas waktu eksekusi satu statement.                                                   | `SET LOCAL statement_timeout = '1s'; SELECT pg_sleep(3);`: `ERROR: canceling statement due to statement timeout`.    |
| idle_in_transaction_session_timeout | Memutus sesi yang diam di dalam transaksi terlalu lama.                                | Diset 5s lalu didiamkan ±8s: `FATAL: terminating connection due to idle-in-transaction timeout`.                     |
| deadlock_timeout                    | Lama menunggu lock sebelum PostgreSQL memeriksa deadlock (bukan batas total menunggu). | Nilai 1s; deadlock Q20 terdeteksi setelah ±1s.                                                                       |

---

### Langkah 5 · SKIP LOCKED dan SERIALIZABLE (Syifa)

#### Q24. SKIP LOCKED

- **Urutan**:
  1. **Sesi A**: `BEGIN; SELECT * FROM lab9.antrean_tugas WHERE id = 1 FOR UPDATE;` (menahan kuncian ID 1).
  2. **Sesi B**: `BEGIN; SELECT * FROM lab9.antrean_tugas WHERE status = 'PENDING' FOR UPDATE SKIP LOCKED LIMIT 1; COMMIT;`
  3. **Sesi A**: `COMMIT;`
- **Hasil**: Sesi B langsung mengembalikan baris **ID 2 (Tugas 2)** tanpa menunggu Sesi A.
- **Penjelasan**: Klausa `SKIP LOCKED` memerintahkan PostgreSQL untuk mengabaikan baris data yang sedang dikunci oleh transaksi lain dan langsung mengambil baris bebas berikutnya. Fitur ini sangat berguna pada arsitektur pemrosesan antrean (_worker queue_), di mana banyak proses _worker_ dapat mengambil dan mengerjakan tugas secara paralel dari tabel yang sama tanpa saling menghambat (_blocking_).

#### Q25. NOWAIT

- **Urutan**:
  1. **Sesi A**: `BEGIN; SELECT * FROM lab9.antrean_tugas WHERE id = 1 FOR UPDATE;`
  2. **Sesi B**: `BEGIN; SELECT * FROM lab9.antrean_tugas WHERE id = 1 FOR UPDATE NOWAIT;`
  3. **Sesi A**: `COMMIT;`
- **Hasil**: Sesi B langsung gagal seketika dan mengembalikan error **`SQLSTATE 55P03`** (`lock_not_available`).
- **Penjelasan**: Klausa `NOWAIT` memaksakan kueri untuk membatalkan eksekusi secara instan jika baris yang diminta sedang dikunci oleh transaksi lain. Berbeda dengan perilaku standar yang akan menunggu (_wait_) hingga kuncian dilepas, `NOWAIT` mencegah aplikasi mengalami penundaan eksekusi yang lama (_hang_) pada sistem berkonkurensi tinggi.

#### Q26. Write skew (REPEATABLE READ)

- **Urutan**:
  1. **Sesi A & Sesi B**: Memulai transaksi dengan `BEGIN ISOLATION LEVEL REPEATABLE READ;`
  2. **Sesi A & Sesi B**: Sama-sama membaca jumlah dokter aktif via `SELECT COUNT(*) FROM lab9.dokter_jaga WHERE aktif = true;` (keduanya mendapat hasil 2).
  3. **Sesi A**: `UPDATE lab9.dokter_jaga SET aktif = false WHERE nama = 'Dr. Alice'; COMMIT;`
  4. **Sesi B**: `UPDATE lab9.dokter_jaga SET aktif = false WHERE nama = 'Dr. Bob'; COMMIT;`
- **Hasil**: Kedua transaksi berhasil `COMMIT`, tetapi tabel `lab9.dokter_jaga` menghasilkan **0 dokter aktif** (Dr. Alice & Dr. Bob sama-sama `false`).
- **Penjelasan**: _Write Skew_ adalah anomali konkurensi di mana dua transaksi membaca sekumpulan data yang sama (_overlapping read set_), lalu membuat keputusan bisnis yang saling bergantung namun memperbarui baris data yang berbeda (_disjoint write set_). Pada isolasi `REPEATABLE READ`, kedua transaksi diizinkan untuk di-`COMMIT` karena tidak ada konflik pembaruan pada baris yang sama, meskipun hasil akhirnya melanggar integritas aturan bisnis.

#### Q27. SERIALIZABLE

- **Urutan**:
  1. Mengulangi langkah pada Q26, tetapi menggunakan `BEGIN ISOLATION LEVEL SERIALIZABLE;` di kedua sesi.
  2. **Sesi A**: Melakukan `UPDATE` pada Dr. Alice dan `COMMIT;` → **Berhasil**.
  3. **Sesi B**: Melakukan `UPDATE` pada Dr. Bob dan `COMMIT;` → **Gagal**.
- **Hasil**: Sesi B dibatalkan saat `COMMIT` dengan mengembalikan error **`SQLSTATE 40001`** (`could not serialize access due to read/write dependencies among transactions`).
- **Penjelasan**: Tingkat isolasi `SERIALIZABLE` berhasil mencegah _Write Skew_. PostgreSQL melacak ketergantungan baca-tulis antar-transaksi (_SIReadLock_) secara internal. Ketika Sesi A melakukan `COMMIT`, PostgreSQL mendeteksi adanya konflik ketergantungan serialisasi (_commit dependency graph_) pada Sesi B, sehingga Sesi B secara otomatis dibatalkan.

#### Q28. SIReadLock

- **Penjelasan**: `SIReadLock` (Serializable Snapshot Isolation Read Lock) adalah mekanisme kunci memori internal PostgreSQL yang mencatat tuple atau halaman yang dibaca oleh transaksi `SERIALIZABLE`. `SIReadLock` tidak bersifat mengunci atau menghalangi (_non-blocking_) operasi baca atau tulis dari transaksi lain, melainkan berfungsi sebagai _predicate lock_ virtual untuk mendeteksi siklus konflik baca-tulis (_rw-antidependencies_). Jika siklus konflik terdeteksi, salah satu transaksi akan digagalkan untuk menjamin eksekusi yang benar-benar serializable.

#### Q29. Pseudocode retry

```python
import time
import random

MAX_RETRIES = 5
BASE_DELAY = 0.1  # detik

def execute_transaction_with_retry(db_connection):
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            with db_connection.begin():
                cursor = db_connection.cursor()
                cursor.execute("SELECT COUNT(*) FROM lab9.dokter_jaga WHERE aktif = true")
                count = cursor.fetchone()[0]

                if count > 1:
                    cursor.execute("UPDATE lab9.dokter_jaga SET aktif = false WHERE nama = 'Dr. Bob'")

            # Operasi eksternal HARUS dilakukan SETELAH commit berhasil
            send_notification_email("Perubahan jadwal dokter berhasil disimpan.")
            return True

        except Exception as e:
            # Periksa jika error berupa SQLSTATE 40001 (Serialization Failure) atau 40P01 (Deadlock)
            if getattr(e, 'pgcode', None) in ['40001', '40P01']:
                if attempt == MAX_RETRIES:
                    raise e
                # Truncated Exponential Backoff dengan Jitter
                sleep_time = (BASE_DELAY * (2 ** (attempt - 1))) + random.uniform(0, 0.1)
                time.sleep(sleep_time)
            else:
                raise e

```

- **Mengapa operasi eksternal dilakukan setelah COMMIT**: Operasi eksternal seperti pengiriman surel, panggilan API pihak ketiga, atau pencetakan struk tidak dapat dibatalkan (_rollback_) jika transaksi basis data di kemudian hari mengalami kegagalan. Jika ditaruh di dalam transaksi dan terjadi _retry_ akibat error `40001`, aksi eksternal tersebut akan terkirim berulang kali padahal transaksi basis datanya dibatalkan.

---

### Langkah 6 · Analisis dan Rekomendasi

#### Q30. Matriks enam anomali (Mael)

| Anomali                       | Cara reproduksi                                                                          | Hasil                                                               | Mitigasi                                                             |
| ----------------------------- | ---------------------------------------------------------------------------------------- | ------------------------------------------------------------------- | -------------------------------------------------------------------- |
| **Dirty read**                | Sesi A update tanpa commit; Sesi B baca dengan `READ UNCOMMITTED`.                       | Data kotor tidak terlihat; Sesi B membaca snapshot commit terakhir. | Arsitektur MVCC PostgreSQL.                                          |
| **Non-repeatable read**       | Sesi A baca baris; Sesi B update + commit baris tsb; Sesi A baca ulang baris tsb.        | Nilai kolom berubah di dalam satu transaksi (Q6).                   | `REPEATABLE READ` atau `SELECT ... FOR SHARE`.                       |
| **Phantom read**              | Sesi A agregasi rentang baris; Sesi B insert baris baru + commit; Sesi A hitung ulang.   | Jumlah baris bertambah pada `READ COMMITTED` (Q8).                  | `REPEATABLE READ` atau `SERIALIZABLE`.                               |
| **Lost update**               | Sesi A & B baca saldo sama; aplikasi hitung manual; keduanya update berurutan.           | Update Sesi A tertimpa oleh Sesi B (Q10).                           | Kalkulasi atomik basis data (`saldo = saldo + x`) atau `FOR UPDATE`. |
| **Write skew**                | Dua transaksi baca kondisi bersama lalu modifikasi baris berbeda (Q26).                  | Aturan bisnis dilanggar (0 dokter aktif).                           | `SERIALIZABLE` (memicu error 40001) atau penguncian rentang.         |
| **Pembacaan tidak konsisten** | Transaksi membaca multi-tabel dengan query terpisah saat transaksi lain memodifikasinya. | Hubungan data tidak sinkron antar-tabel.                            | Transaksi terisolasi dengan level `REPEATABLE READ`.                 |

#### Q31. Rekomendasi isolation level (Syifa)

| Kebutuhan                           | Isolation level       | Kompromi dan risiko                                                                                                                                                                                                                                                 |
| ----------------------------------- | --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Pembacaan sederhana                 | **`READ COMMITTED`**  | Performa paling tinggi dan _overhead_ rendah, namun rentan terhadap _Non-repeatable read_ dan _Phantom read_ jika ada pembaruan dari sesi lain antar-pernyataan.                                                                                                    |
| Laporan dengan snapshot konsisten   | **`REPEATABLE READ`** | Menjamin konsistensi pembacaan data di seluruh transaksi (_point-in-time snapshot_), namun berisiko mengalami _Write Skew_ jika digunakan pada transaksi pembaruan multi-baris.                                                                                     |
| Aturan bisnis lintas beberapa baris | **`SERIALIZABLE`**    | Menjamin integritas data total dan mencegah seluruh anomali (termasuk _Write Skew_), tetapi memiliki kompromi _overhead_ performa dan risiko transaksi digagalkan dengan error `SQLSTATE 40001` sehingga wajib mengimplementasikan logika _retry_ di sisi aplikasi. |

---

#### Q32. Tiga pelajaran utama (Agi)

1. Menghitung nilai di database lebih aman daripada menulis hasil hitung lama. Pada Q10, dua sesi menulis nilai tetap dari bacaan lama dan saldo berakhir 900.000 padahal seharusnya 1.100.000, tanpa error apa pun. Pada Q12, SET saldo = saldo - 10000 membuat dua pengurangan sama-sama tercatat (980.000). Pada Q13, FOR UPDATE membuat Sesi B menunggu lalu membaca 990.000. Pada Q14, UPDATE 0 memberi tahu aplikasi bahwa versi 1 sudah basi.
2. Isolation level menentukan anomali yang muncul, dan hanya SERIALIZABLE menutup write skew, dengan syarat aplikasi siap mengulang. Pada Q6, READ COMMITTED menghasilkan pembacaan 1.000.000 lalu 1.200.000, sedangkan Q7 (REPEATABLE READ) tetap 1.200.000. Pada Q26 (REPEATABLE READ) kedua transaksi COMMIT dan dokter aktif menjadi 0; pada Q27 (SERIALIZABLE) salah satu transaksi gagal dengan SQLSTATE 40001. Karena itu transaksi harus bisa diulang (Q29).
3. Lock dan MVCC punya harga: urutan kunci, antrean, dan versi lama. Pada Q20, urutan kunci berlawanan menghasilkan deadlock 40P01 (korban Sesi B, PID 392), sedangkan pada Q21 urutan id 1 lalu 2 tidak error. Pada Q22, penunggu terlihat Lock/transactionid dengan diblokir_oleh = {377} tanpa error otomatis, sehingga timeout (Q23) perlu dipasang. Pada Q15 pembaca tidak menunggu penulis berkat MVCC, tetapi Q17 menunjukkan sekitar 6 versi lama yang perlu dibersihkan vacuum.

---

## 3. Bukti

Seluruh bukti ada di folder `bukti/`:

- `isolation-level.md` (Q6-Q11)
- `deadlock.md` (Q18-Q23)
- `serializable.md` (Q24-Q29)
- `hasil-sesi.txt` (output terminal Sesi A dan B)

## 4. Tabel Ringkasan Anomali

| Anomali                       | Penyebab                                                                                                      | Dampak                                                                      | Mitigasi                                                                               |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| **Dirty read**                | Membaca perubahan data transaksi lain yang belum berstatus commit.                                            | Keputusan bisnis diambil dari data yang berpotensi dibatalkan (_rollback_). | Gunakan isolasi minimal `READ COMMITTED` (default PostgreSQL).                         |
| **Non-repeatable read**       | Statement membaca data yang diubah dan di-commit transaksi lain di tengah transaksi aktif.                    | Nilai data tidak konsisten dalam proses transaksi bertahap.                 | Gunakan `REPEATABLE READ` atau kunci baris pesimistik.                                 |
| **Phantom read**              | Kueri rentang membaca tuple baru hasil _insert/delete_ transaksi lain yang telah commit.                      | Agregasi dan laporan batch menghasilkan data yang berubah-ubah.             | Terapkan isolasi `REPEATABLE READ` atau `SERIALIZABLE`.                                |
| **Lost update**               | Penulisan nilai hardcoded hasil hitungan aplikasi menimpa pembaruan transaksi konkuren.                       | Kehilangan data finansial/transaksional yang sah secara permanen.           | Atomic update (`SET col = col + x`), pesimistik lock (`FOR UPDATE`), atau nomor versi. |
| **Write skew**                | Keputusan modifikasi pada baris terpisah didasarkan pada dataset bacaan yang tumpang tindih.                  | Pelanggaran aturan bisnis/invarian sistem secara menyeluruh.                | Terapkan level `SERIALIZABLE` dengan mekanisme retry error 40001.                      |
| **Pembacaan tidak konsisten** | Beberapa query terpisah dalam satu proses membaca snapshot berbeda ketika transaksi lain commit di antaranya. | Laporan atau hubungan antartabel tidak sinkron.                             | Satu transaksi REPEATABLE READ agar semua query memakai snapshot yang sama.            |

## 5. Kesimpulan

Eksperimen dua sesi menunjukkan bahwa transaksi saja tidak cukup untuk menjaga data tetap benar saat banyak sesi bekerja bersamaan. Lost update terjadi tanpa error ketika aplikasi menulis nilai hasil hitung lama (Q10: 900.000, seharusnya 1.100.000), dan dapat dicegah dengan pembaruan atomik (Q12), FOR UPDATE (Q13), atau version_no (Q14, ditandai UPDATE 0). Isolation level mengubah apa yang terlihat: READ COMMITTED membaca snapshot per statement (Q6, Q8), REPEATABLE READ per transaksi (Q7), tetapi write skew baru tertutup oleh SERIALIZABLE yang membatalkan salah satu transaksi dengan SQLSTATE 40001 (Q26-Q27), sehingga aplikasi harus mengulang transaksi. Lock menimbulkan risiko deadlock 40P01 (Q20), yang dihindari dengan urutan penguncian konsisten (Q21), dan antrean lock panjang yang dibatasi dengan timeout (Q22-Q23). MVCC memungkinkan pembaca tidak menunggu penulis (Q15), dengan konsekuensi versi lama menumpuk (Q16-Q17) yang perlu dibersihkan vacuum.

## 6. Pengungkapan Penggunaan AI

Saya menggunakan AI assistant sebagai teman diskusi untuk memahami konsep dasar _Write Skew_, menganalisis mekanisme penanganan kesalahan pada `SERIALIZABLE`. Seluruh pengujian dua sesi dijalankan secara mandiri pada PostgreSQL 17 di Docker lokal, dan seluruh kode error (`SQLSTATE 40001` & `55P03`) serta log bukti hasil pengujian diambil dari eksekusi terminal nyata.

```

---

## 7. Kontribusi Anggota

| Nama                       | NIM       | Bagian                                     |
| -------------------------- | --------- | ------------------------------------------ |
| Jelita Hati Sinurat        | 251402141 | q00_setup.sql, Q1-Q5, README.md, tautan MR |
| M. Dzakwan Ismail Rangkuti | 251402014 | Q6-Q11, Q30, bukti/isolation-level.md      |
| Agi Aginta Sembiring       | 251402059 | Q12-Q17, Q32                               |
| M. Azkha Amorie            | 251402092 | Q18-Q23, lingkungan, bukti/deadlock.md     |
| Syifa Nazira               | 251402126 | Q24-Q29, Q31, bukti/serializable.md        |

**Tautan Merge Request:** _(diisi Jelita setelah semua branch digabung)_
```
