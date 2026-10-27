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

- Urutan:
- Hasil:
- Penjelasan:

#### Q7. Perbandingan dengan REPEATABLE READ

- Urutan:
- Hasil:
- Penjelasan:

#### Q8. Phantom read

- Urutan:
- Hasil (READ COMMITTED vs REPEATABLE READ):
- Penjelasan:

#### Q9. Dirty read dan READ UNCOMMITTED

- Urutan:
- Hasil:
- Penjelasan:

#### Q10. Lost update

- Urutan:
- Hasil:
- Penjelasan:

#### Q11. Tabel ringkas anomali

| Anomali | Urutan kejadian | Isolation level | Hasil yang diamati | Cara mencegah/menangani |
| ------- | --------------- | --------------- | ------------------ | ----------------------- |
|         |                 |                 |                    |                         |

---

### Langkah 3 · Mencegah Lost Update dan MVCC (Agi)

#### Q12. Pembaruan atomik

- Urutan:
- Hasil:
- Penjelasan (mengapa menghitung di database lebih aman):

#### Q13. SELECT ... FOR UPDATE

- Urutan (kapan sesi kedua menunggu):
- Hasil:
- Penjelasan:

#### Q14. Optimistic locking (`version_no`)

- Urutan:
- Hasil:
- Penjelasan:

#### Q15. MVCC dan snapshot

- Urutan:
- Hasil:
- Penjelasan:

#### Q16. xmin dan xmax

- Hasil query:
- Penjelasan:

#### Q17. Manfaat MVCC dan peran vacuum

- Hasil (`n_dead_tup`, VACUUM):
- Penjelasan:

---

### Langkah 4 · Row Lock, Deadlock, dan Antrean Lock (Azkha)

#### Q18. FOR UPDATE / NO KEY UPDATE / SHARE / KEY SHARE

| Mode              | Tujuan umum | Kapan transaksi lain terhalang |
| ----------------- | ----------- | ------------------------------ |
| FOR UPDATE        |             |                                |
| FOR NO KEY UPDATE |             |                                |
| FOR SHARE         |             |                                |
| FOR KEY SHARE     |             |                                |

#### Q19. Penguncian baris yang sama

- Urutan:
- Hasil:
- Penjelasan:

#### Q20. Deadlock

- Urutan:
- Hasil (sesi yang kena, SQLSTATE 40P01):
- Penjelasan:

#### Q21. Urutan penguncian konsisten

- Urutan:
- Hasil:
- Penjelasan:

#### Q22. Deadlock vs antrean lock panjang

- Contoh transaksi yang menahan lock terlalu lama:
- Hasil `pg_stat_activity` / `pg_locks`:
- Penjelasan:

#### Q23. Perbandingan timeout

| Parameter                           | Fungsi | Hasil uji |
| ----------------------------------- | ------ | --------- |
| lock_timeout                        |        |           |
| statement_timeout                   |        |           |
| idle_in_transaction_session_timeout |        |           |
| deadlock_timeout                    |        |           |

---

### Langkah 5 · SKIP LOCKED dan SERIALIZABLE (Syifa)

#### Q24. SKIP LOCKED

- **Urutan**:
  1. **Sesi A**: `BEGIN; SELECT * FROM lab9.antrean_tugas WHERE id = 1 FOR UPDATE;` (menahan kuncian ID 1).
  2. **Sesi B**: `BEGIN; SELECT * FROM lab9.antrean_tugas WHERE status = 'PENDING' FOR UPDATE SKIP LOCKED LIMIT 1; COMMIT;`
  3. **Sesi A**: `COMMIT;`
- **Hasil**: Sesi B langsung mengembalikan baris **ID 2 (Tugas 2)** tanpa menunggu Sesi A.
- **Penjelasan**: Klausa `SKIP LOCKED` memerintahkan PostgreSQL untuk mengabaikan baris data yang sedang dikunci oleh transaksi lain dan langsung mengambil baris bebas berikutnya. Fitur ini sangat berguna pada arsitektur pemrosesan antrean (*worker queue*), di mana banyak proses *worker* dapat mengambil dan mengerjakan tugas secara paralel dari tabel yang sama tanpa saling menghambat (*blocking*).

#### Q25. NOWAIT

- **Urutan**:
  1. **Sesi A**: `BEGIN; SELECT * FROM lab9.antrean_tugas WHERE id = 1 FOR UPDATE;`
  2. **Sesi B**: `BEGIN; SELECT * FROM lab9.antrean_tugas WHERE id = 1 FOR UPDATE NOWAIT;`
  3. **Sesi A**: `COMMIT;`
- **Hasil**: Sesi B langsung gagal seketika dan mengembalikan error **`SQLSTATE 55P03`** (`lock_not_available`).
- **Penjelasan**: Klausa `NOWAIT` memaksakan kueri untuk membatalkan eksekusi secara instan jika baris yang diminta sedang dikunci oleh transaksi lain. Berbeda dengan perilaku standar yang akan menunggu (*wait*) hingga kuncian dilepas, `NOWAIT` mencegah aplikasi mengalami penundaan eksekusi yang lama (*hang*) pada sistem berkonkurensi tinggi.

#### Q26. Write skew (REPEATABLE READ)

- **Urutan**:
  1. **Sesi A & Sesi B**: Memulai transaksi dengan `BEGIN ISOLATION LEVEL REPEATABLE READ;`
  2. **Sesi A & Sesi B**: Sama-sama membaca jumlah dokter aktif via `SELECT COUNT(*) FROM lab9.dokter_jaga WHERE aktif = true;` (keduanya mendapat hasil 2).
  3. **Sesi A**: `UPDATE lab9.dokter_jaga SET aktif = false WHERE nama = 'Dr. Alice'; COMMIT;`
  4. **Sesi B**: `UPDATE lab9.dokter_jaga SET aktif = false WHERE nama = 'Dr. Bob'; COMMIT;`
- **Hasil**: Kedua transaksi berhasil `COMMIT`, tetapi tabel `lab9.dokter_jaga` menghasilkan **0 dokter aktif** (Dr. Alice & Dr. Bob sama-sama `false`).
- **Penjelasan**: *Write Skew* adalah anomali konkurensi di mana dua transaksi membaca sekumpulan data yang sama (*overlapping read set*), lalu membuat keputusan bisnis yang saling bergantung namun memperbarui baris data yang berbeda (*disjoint write set*). Pada isolasi `REPEATABLE READ`, kedua transaksi diizinkan untuk di-`COMMIT` karena tidak ada konflik pembaruan pada baris yang sama, meskipun hasil akhirnya melanggar integritas aturan bisnis.

#### Q27. SERIALIZABLE

- **Urutan**:
  1. Mengulangi langkah pada Q26, tetapi menggunakan `BEGIN ISOLATION LEVEL SERIALIZABLE;` di kedua sesi.
  2. **Sesi A**: Melakukan `UPDATE` pada Dr. Alice dan `COMMIT;` → **Berhasil**.
  3. **Sesi B**: Melakukan `UPDATE` pada Dr. Bob dan `COMMIT;` → **Gagal**.
- **Hasil**: Sesi B dibatalkan saat `COMMIT` dengan mengembalikan error **`SQLSTATE 40001`** (`could not serialize access due to read/write dependencies among transactions`).
- **Penjelasan**: Tingkat isolasi `SERIALIZABLE` berhasil mencegah *Write Skew*. PostgreSQL melacak ketergantungan baca-tulis antar-transaksi (*SIReadLock*) secara internal. Ketika Sesi A melakukan `COMMIT`, PostgreSQL mendeteksi adanya konflik ketergantungan serialisasi (*commit dependency graph*) pada Sesi B, sehingga Sesi B secara otomatis dibatalkan.

#### Q28. SIReadLock

- **Penjelasan**: `SIReadLock` (Serializable Snapshot Isolation Read Lock) adalah mekanisme kunci memori internal PostgreSQL yang mencatat tuple atau halaman yang dibaca oleh transaksi `SERIALIZABLE`. `SIReadLock` tidak bersifat mengunci atau menghalangi (*non-blocking*) operasi baca atau tulis dari transaksi lain, melainkan berfungsi sebagai *predicate lock* virtual untuk mendeteksi siklus konflik baca-tulis (*rw-antidependencies*). Jika siklus konflik terdeteksi, salah satu transaksi akan digagalkan untuk menjamin eksekusi yang benar-benar serializable.

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

* **Mengapa operasi eksternal dilakukan setelah COMMIT**: Operasi eksternal seperti pengiriman surel, panggilan API pihak ketiga, atau pencetakan struk tidak dapat dibatalkan (*rollback*) jika transaksi basis data di kemudian hari mengalami kegagalan. Jika ditaruh di dalam transaksi dan terjadi *retry* akibat error `40001`, aksi eksternal tersebut akan terkirim berulang kali padahal transaksi basis datanya dibatalkan.

---


### Langkah 6 · Analisis dan Rekomendasi

#### Q30. Matriks enam anomali (Mael)

| Anomali                   | Cara reproduksi | Hasil | Mitigasi |
| ------------------------- | --------------- | ----- | -------- |
| Dirty read                |                 |       |          |
| Non-repeatable read       |                 |       |          |
| Phantom read              |                 |       |          |
| Lost update               |                 |       |          |
| Write skew                |                 |       |          |
| Pembacaan tidak konsisten |                 |       |          |

#### Q31. Rekomendasi isolation level (Syifa)

| Kebutuhan | Isolation level | Kompromi dan risiko |
| --- | --- | --- |
| Pembacaan sederhana | **`READ COMMITTED`** | Performa paling tinggi dan *overhead* rendah, namun rentan terhadap *Non-repeatable read* dan *Phantom read* jika ada pembaruan dari sesi lain antar-pernyataan. |
| Laporan dengan snapshot konsisten | **`REPEATABLE READ`** | Menjamin konsistensi pembacaan data di seluruh transaksi (*point-in-time snapshot*), namun berisiko mengalami *Write Skew* jika digunakan pada transaksi pembaruan multi-baris. |
| Aturan bisnis lintas beberapa baris | **`SERIALIZABLE`** | Menjamin integritas data total dan mencegah seluruh anomali (termasuk *Write Skew*), tetapi memiliki kompromi *overhead* performa dan risiko transaksi digagalkan dengan error `SQLSTATE 40001` sehingga wajib mengimplementasikan logika *retry* di sisi aplikasi. |

---

#### Q32. Tiga pelajaran utama (Agi)

1. _(didukung bukti: query / urutan kejadian / pesan error)_
2.
3.

---

## 3. Bukti

Seluruh bukti ada di folder `bukti/`:

- `isolation-level.md` (Q6-Q11)
- `deadlock.md` (Q18-Q23)
- `serializable.md` (Q24-Q29)
- `hasil-sesi.txt` (output terminal Sesi A dan B)

## 4. Tabel Ringkasan Anomali

| Anomali             | Penyebab | Dampak | Mitigasi |
| ------------------- | -------- | ------ | -------- |
| Dirty read          |          |        |          |
| Non-repeatable read |          |        |          |
| Phantom read        |          |        |          |
| Lost update         |          |        |          |
| Write skew          |          |        |          |

## 5. Kesimpulan

_(berbasis hasil eksperimen)_

## 6. Pengungkapan Penggunaan AI

Saya menggunakan AI assistant sebagai teman diskusi untuk memahami konsep dasar *Write Skew*, menganalisis mekanisme penanganan kesalahan pada `SERIALIZABLE`. Seluruh pengujian dua sesi dijalankan secara mandiri pada PostgreSQL 17 di Docker lokal, dan seluruh kode error (`SQLSTATE 40001` & `55P03`) serta log bukti hasil pengujian diambil dari eksekusi terminal nyata.

```

---

## 7. Kontribusi Anggota

| Nama                       | NIM       | Bagian                                     |
| -------------------------- | --------- | ------------------------------------------ |
| Jelita Hati Sinurat        | 251402141 | q00_setup.sql, Q1-Q5, README.md, tautan MR |
| M. Ismail Dzakwan Rangkuti | 251402014 | Q6-Q11, Q30, bukti/isolation-level.md      |
| Agi Aginta Sembiring       | 251402059 | Q12-Q17, Q32                               |
| M. Azkha Amorie            | 251402092 | Q18-Q23, lingkungan, bukti/deadlock.md     |
| Syifa Nazira               | 251402126 | Q24-Q29, Q31, bukti/serializable.md        |

**Tautan Merge Request:** _(diisi Jelita setelah semua branch digabung)_
