# Bukti Pengujian SERIALIZABLE & Fitur Lanjutan (Q24–Q29)

**Penguji**: Syifa Nazira (251402126)  
**Lingkungan**: PostgreSQL 17 (Docker `msbd-pg`)

---

## 1. Q24 — SKIP LOCKED

### Setup Tabel Antrean
```sql
CREATE TABLE IF NOT EXISTS lab9.antrean_tugas (
    id SERIAL PRIMARY KEY,
    deskripsi TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'PENDING'
);

INSERT INTO lab9.antrean_tugas (deskripsi) VALUES ('Tugas 1'), ('Tugas 2');

```

### Eksekusi Dua Sesi

* **Sesi A (Kunci ID 1):**
```sql
BEGIN;
SELECT * FROM lab9.antrean_tugas WHERE id = 1 FOR UPDATE;
-- Output:
--  id | deskripsi | status  
-- ----+-----------+---------
--   1 | Tugas 1   | PENDING

```

* **Sesi B (SKIP LOCKED):**
```sql
BEGIN;
SELECT * FROM lab9.antrean_tugas WHERE status = 'PENDING' FOR UPDATE SKIP LOCKED LIMIT 1;
-- Output:
--  id | deskripsi | status  
-- ----+-----------+---------
--   2 | Tugas 2   | PENDING
COMMIT;

```

* **Sesi A (Selesai):**
```sql
COMMIT;

```

*Analisis*: Sesi B tidak mengalami penundaan (*blocked*) saat mengeksekusi kueri, melainkan secara otomatis melompati baris ID 1 yang sedang dikunci oleh Sesi A dan langsung mengambil baris bebas berikutnya (ID 2).

---

## 2. Q25 — NOWAIT

### Eksekusi Dua Sesi

* **Sesi A (Kunci ID 1 kembali):**
```sql
BEGIN;
SELECT * FROM lab9.antrean_tugas WHERE id = 1 FOR UPDATE;

```

* **Sesi B (NOWAIT):**
```sql
BEGIN;
SELECT * FROM lab9.antrean_tugas WHERE id = 1 FOR UPDATE NOWAIT;
-- Output Terminal (Error):
-- ERROR:  could not obtain lock on row in relation "antrean_tugas"
-- ERROR CODE: 55P03
ROLLBACK;

```

* **Sesi A (Selesai):**
```sql
COMMIT;

```

*Analisis*: Berbeda dengan penguncian standar yang membuat transaksi menggantung untuk menunggu kuncian dilepas, klausa `NOWAIT` membatalkan transaksi Sesi B secara instan dengan mengembalikan error `SQLSTATE 55P03`.

---

## 3. Q26 — Write Skew pada REPEATABLE READ

### Setup Tabel Dokter Jaga

```sql
CREATE TABLE IF NOT EXISTS lab9.dokter_jaga (
    id SERIAL PRIMARY KEY,
    nama TEXT NOT NULL,
    aktif BOOLEAN NOT NULL DEFAULT TRUE
);

INSERT INTO lab9.dokter_jaga (nama, aktif) VALUES ('Dr. Alice', true), ('Dr. Bob', true);

```

### Eksekusi Kronologis Dua Sesi

1. **Sesi A**: `BEGIN ISOLATION LEVEL REPEATABLE READ;`
2. **Sesi B**: `BEGIN ISOLATION LEVEL REPEATABLE READ;`
3. **Sesi A**: `SELECT COUNT(*) FROM lab9.dokter_jaga WHERE aktif = true;` → **Hasil: 2**
4. **Sesi B**: `SELECT COUNT(*) FROM lab9.dokter_jaga WHERE aktif = true;` → **Hasil: 2**
5. **Sesi A**: `UPDATE lab9.dokter_jaga SET aktif = false WHERE nama = 'Dr. Alice';`
6. **Sesi A**: `COMMIT;`
7. **Sesi B**: `UPDATE lab9.dokter_jaga SET aktif = false WHERE nama = 'Dr. Bob';`
8. **Sesi B**: `COMMIT;`

### Hasil Verifikasi Akhir

```sql
SELECT * FROM lab9.dokter_jaga;
--  id |   nama    | aktif 
----+-----------+-------
--   1 | Dr. Alice | f
--   2 | Dr. Bob   | f

```

*Analisis*: Kedua transaksi berhasil di-`COMMIT` tanpa adanya penolakan dari sistem. Namun, aturan bisnis yang mensyaratkan minimal ada 1 dokter aktif menjadi terlanggar (hasil akhir 0 dokter aktif). Anomali ini disebut **Write Skew**.

---

## 4. Q27 — Mencegah Write Skew dengan SERIALIZABLE

### Reset Data Dokter

```sql
UPDATE lab9.dokter_jaga SET aktif = true;

```

### Eksekusi Kronologis Dua Sesi

1. **Sesi A**: `BEGIN ISOLATION LEVEL SERIALIZABLE;`
2. **Sesi B**: `BEGIN ISOLATION LEVEL SERIALIZABLE;`
3. **Sesi A**: `SELECT COUNT(*) FROM lab9.dokter_jaga WHERE aktif = true;` → **Hasil: 2**
4. **Sesi B**: `SELECT COUNT(*) FROM lab9.dokter_jaga WHERE aktif = true;` → **Hasil: 2**
5. **Sesi A**: `UPDATE lab9.dokter_jaga SET aktif = false WHERE nama = 'Dr. Alice';`
6. **Sesi A**: `COMMIT;` → **BERHASIL**
7. **Sesi B**: `UPDATE lab9.dokter_jaga SET aktif = false WHERE nama = 'Dr. Bob';`
8. **Sesi B**: `COMMIT;` → **GAGAL**

### Output Terminal Error Sesi B

```text
ERROR:  could not serialize access due to read/write dependencies among transactions
DETAIL:  Reason code: Canceled on identification as a pivot in a commit dependency graph.
HINT:  The transaction might succeed if it restarted.
SQLSTATE: 40001

```

*Analisis*: Tingkat isolasi `SERIALIZABLE` berhasil menggagalkan Sesi B dengan mengembalikan error `SQLSTATE 40001` saat `COMMIT`, sehingga aturan bisnis tetap terjaga (Dr. Alice dinonaktifkan, tetapi Dr. Bob tetap aktif).

---

## 5. Q28 — Pemeriksaan SIReadLock dan SERIALIZABLE

* **Peran SIReadLock**: `SIReadLock` adalah struktur kunci memori (*in-memory lock*) yang mencatat baris atau tabel mana saja yang dibaca oleh transaksi `SERIALIZABLE`.
* **Mengapa Tidak Mengunci Seperti `FOR UPDATE**`: `SIReadLock` tidak melakukan blokir fisik pada operasi pembacaan atau penulisan transaksi lain (*non-blocking*). Ia hanya berfungsi sebagai tanda acuan (*predicate lock*) untuk mendeteksi siklus ketergantungan baca-tulis (*rw-antidependency graph*). Jika terjadi siklus konflik antar-transaksi, PostgreSQL akan menginterupsi salah satu transaksi dengan error `40001`.

---

## 6. Q29 — Pseudocode Logic Retry & Operasi Eksternal

### Pseudocode Implementation (Python)

```python
import time
import random

MAX_RETRIES = 5
BASE_DELAY = 0.1  # detik

def update_jadwal_dokter_with_retry(db_connection):
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            with db_connection.begin():
                cursor = db_connection.cursor()
                cursor.execute("SELECT COUNT(*) FROM lab9.dokter_jaga WHERE aktif = true")
                count = cursor.fetchone()[0]
                
                if count > 1:
                    cursor.execute("UPDATE lab9.dokter_jaga SET aktif = false WHERE nama = 'Dr. Bob'")
            
            # Operasi eksternal dipanggil SETELAH commit berhasil
            send_notification_email("Perubahan jadwal dokter berhasil disimpan.")
            return True

        except Exception as e:
            # Mengecek error SQLSTATE 40001 (Serialization Failure) atau 40P01 (Deadlock)
            if getattr(e, 'pgcode', None) in ['40001', '40P01']:
                if attempt == MAX_RETRIES:
                    raise e
                # Truncated Exponential Backoff dengan Jitter
                sleep_time = (BASE_DELAY * (2 ** (attempt - 1))) + random.uniform(0, 0.1)
                time.sleep(sleep_time)
            else:
                raise e

```

* **Penjelasan Operasi Eksternal**: Operasi eksternal seperti pengiriman email, pengiriman pesan SMS, atau *WebHook notification* harus selalu diletakkan **di luar** dan **setelah** transaksi basis data sukses ter-`COMMIT`. Jika ditaruh di dalam blok transaksi dan terjadi *retry* akibat error `40001`, aksi eksternal tersebut akan tereksekusi berulang kali atau terlanjur terkirim padahal transaksi basis datanya dibatalkan (*rollback*).

```

---
   