# Bukti Pengujian Isolation Level dan Anomali (Q6-Q11)

## Lingkungan

| Item | Nilai |
|---|---|
| PostgreSQL | 17 (isi versi lengkap dari `SELECT version();`) |
| Alat | DBeaver, dua SQL Editor terpisah (Sesi A dan Sesi B) |
| Skema | `lab9` |
| Data awal | Ani (id 1) = 1.000.000, Budi (id 2) = 1.000.000 (`q00_setup.sql`) |
| Konfigurasi | Default; tidak ada timeout yang diubah |

Pengujian memakai dua sesi koneksi concurrent: **[A]** dan **[B]**.

---

## Q6 - Non-repeatable Read (READ COMMITTED)

| No | Sesi | Perintah | Hasil |
|---|---|---|---|
| 1 | A | `BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;` | BEGIN |
| 2 | A | `SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;` | `1000000.00` |
| 3 | B | `UPDATE lab9.rekening SET saldo = 1200000 WHERE rekening_id = 1; COMMIT;` | UPDATE 1, COMMIT |
| 4 | A | `SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;` | `1200000.00` |
| 5 | A | `COMMIT;` | COMMIT |

**Analisis:** hasil dua pembacaan di Sesi A **berubah** (1.000.000 menjadi 1.200.000) dalam satu transaksi. Pada `READ COMMITTED`, setiap perintah mengambil snapshot terbaru yang sudah di-commit saat statement itu dieksekusi, sehingga terjadi non-repeatable read.

## Q7 - REPEATABLE READ

| No | Sesi | Perintah | Hasil |
|---|---|---|---|
| 1 | A | `BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;` | BEGIN |
| 2 | A | `SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;` | `1200000.00` |
| 3 | B | `UPDATE lab9.rekening SET saldo = 1500000 WHERE rekening_id = 1; COMMIT;` | UPDATE 1, COMMIT |
| 4 | A | `SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;` | `1200000.00` (tidak berubah) |
| 5 | A | `COMMIT;` | COMMIT |

**Analisis:** pada `REPEATABLE READ`, snapshot dibekukan sejak statement pertama dalam transaksi, jadi perubahan Sesi B yang sudah commit tidak terlihat sampai transaksi A selesai. Perbedaan dengan Q6: `READ COMMITTED` mengambil snapshot per statement, `REPEATABLE READ` per transaksi.

## Q8 - Phantom Read

Kondisi hitung: `saldo >= 1000000`.

**READ COMMITTED**

| No | Sesi | Perintah | Hasil |
|---|---|---|---|
| 1 | A | `BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;` lalu `SELECT COUNT(*) FROM lab9.rekening WHERE saldo >= 1000000;` | `2` |
| 2 | B | `INSERT INTO lab9.rekening VALUES (3, 'Citra', 2000000); COMMIT;` | INSERT 0 1, COMMIT |
| 3 | A | `SELECT COUNT(*) FROM lab9.rekening WHERE saldo >= 1000000;` | `3` (phantom row muncul) |
| 4 | A | `COMMIT;` | COMMIT |

**REPEATABLE READ**

| No | Sesi | Perintah | Hasil |
|---|---|---|---|
| 1 | A | `BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;` lalu `SELECT COUNT(*) FROM lab9.rekening WHERE saldo >= 1000000;` | `3` |
| 2 | B | `INSERT INTO lab9.rekening VALUES (4, 'Doni', 2500000); COMMIT;` | INSERT 0 1, COMMIT |
| 3 | A | `SELECT COUNT(*) FROM lab9.rekening WHERE saldo >= 1000000;` | `3` (phantom row dicegah) |
| 4 | A | `COMMIT;` | COMMIT |

**Analisis:** standar SQL mengizinkan phantom read pada REPEATABLE READ, tetapi implementasi snapshot (MVCC) PostgreSQL mencegahnya.

## Q9 - Dirty Read dan READ UNCOMMITTED

| No | Sesi | Perintah | Hasil |
|---|---|---|---|
| 1 | A | `BEGIN; UPDATE lab9.rekening SET saldo = 5000000 WHERE rekening_id = 1;` (tanpa COMMIT) | UPDATE 1 |
| 2 | B | `BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;` | BEGIN |
| 3 | B | `SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;` | `1500000.00` (perubahan A tidak terbaca) |
| 4 | B | `COMMIT;` | COMMIT |
| 5 | A | `ROLLBACK;` | ROLLBACK |

**Analisis:** PostgreSQL tidak mendukung dirty read. `READ UNCOMMITTED` diterima secara sintaks, tetapi secara internal berjalan identik dengan `READ COMMITTED`.

## Q10 - Lost Update

Isolation level: READ COMMITTED (default). Saldo awal rekening 1 dikembalikan ke 1.000.000 sebelum eksperimen.

| No | Sesi | Perintah | Hasil |
|---|---|---|---|
| 1 | A | `BEGIN; SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;` | `1000000.00` |
| 2 | B | `BEGIN; SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;` | `1000000.00` |
| 3 | A | Aplikasi menghitung +200000, lalu `UPDATE lab9.rekening SET saldo = 1200000 WHERE rekening_id = 1; COMMIT;` | UPDATE 1, COMMIT |
| 4 | B | Aplikasi menghitung -100000, lalu `UPDATE lab9.rekening SET saldo = 900000 WHERE rekening_id = 1; COMMIT;` | UPDATE 1, COMMIT |
| 5 | - | `SELECT saldo FROM lab9.rekening WHERE rekening_id = 1;` | `900000.00` |

**Analisis:** saldo yang benar seharusnya **1.100.000** (1.000.000 + 200.000 - 100.000), tetapi hasil akhirnya **900.000**. Setoran 200.000 dari Sesi A hilang karena Sesi B menulis nilai tetap yang dihitung dari bacaan lama. Kedua UPDATE sukses tanpa error sehingga masalah tidak terdeteksi.

## Q11 - Ringkasan Anomali

| Anomali | Urutan kejadian | Isolation level | Hasil yang diamati | Pencegahan / penanganan |
|---|---|---|---|---|
| Non-repeatable read | A baca, B update + COMMIT, A baca lagi | READ COMMITTED | 1.000.000 lalu 1.200.000 | REPEATABLE READ atau lebih tinggi |
| Phantom read | A hitung, B insert + COMMIT, A hitung lagi | READ COMMITTED | COUNT 2 lalu 3 | REPEATABLE READ (di PostgreSQL COUNT tetap 3) |
| Dirty read | A update belum COMMIT, B baca | READ UNCOMMITTED | B tetap membaca 1.500.000 | Tidak terjadi di PostgreSQL |
| Lost update | A dan B baca nilai sama, keduanya menulis nilai tetap | READ COMMITTED | Saldo akhir 900.000 (seharusnya 1.100.000) | Update atomik (`saldo = saldo + x`), `SELECT ... FOR UPDATE`, atau `version_no` |

## Pemulihan data awal

Setelah eksperimen, jalankan ulang `q00_setup.sql` dan hapus baris tambahan:

```sql
DELETE FROM lab9.rekening WHERE rekening_id > 2;
```