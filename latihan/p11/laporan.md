# Laporan Latihan Kelompok Pertemuan 11
**Menutup Pintu yang Terbuka** · Manajemen Sistem Basis Data

Kelompok: ........ · Cabang: `latihan/p11-keamanan` · Merge request: <tempel tautan>

## Anggota dan Kontribusi
| Nama                       | NIM       | Kontribusi                                             | Commit |
|----------------------------|-----------|--------------------------------------------------------|--------|
| Jelita Hati Sinurat        | 251402141 | Setup, Q1–Q5, README, integrasi laporan, merge request |        |
| M. Dzakwan Ismail Rangkuti | 251402014 | RLS Q6–Q11, Refleksi B                                 |        |
| Agi Aginta Sembiring       | 251402059 | Injection Q12–Q18, `rentan.py`, Refleksi C             |        |
| M. Azkha Amorie            | 251402092 | Enkripsi dan penyamaran Q19–Q24, Refleksi D            |        |
| Syifa Nazira               | 251402126 | Audit dan UU PDP Q25–Q30, Refleksi E                   |        |

## Bukti Setup (q00)
Peran: `postgres`

```text
-- hasil: tenant | pelanggan | akun | transaksi  (harapkan 3 | 30000 | 4 | 120000)
-- hasil: jumlah pelanggan per penyewa (harapkan 10000 tiap penyewa)
-- hasil: docker network inspect lab11_labnet --format '{{.Internal}}'  (harapkan true)
```

## Q1–Q30
Format tiap soal: peran, perintah, keluaran nyata, uji negatif, alasan keputusan.

### Q1 · Hak pemilik tidak bisa dicabut
**Penanggung jawab:** Jelita · **Berkas:** `q01_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q2 · DROP bukan hak yang bisa di-REVOKE
**Penanggung jawab:** Jelita · **Berkas:** `q02_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q3 · Default privileges
**Penanggung jawab:** Jelita · **Berkas:** `q03_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q4 · GRANT OPTION dan CASCADE
**Penanggung jawab:** Jelita · **Berkas:** `q04_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q5 · Tabel tujuh peran
**Penanggung jawab:** Jelita · **Berkas:** `q05_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q6 · Default deny RLS
**Penanggung jawab:** Mael · **Berkas:** `q06_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q7 · Kebijakan isolasi penyewa
**Penanggung jawab:** Mael · **Berkas:** `q07_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q8 · Uji positif dan negatif
**Penanggung jawab:** Mael · **Berkas:** `q08_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q9 · FORCE RLS dan BYPASSRLS
**Penanggung jawab:** Mael · **Berkas:** `q09_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q10 · Kolam koneksi
**Penanggung jawab:** Mael · **Berkas:** `q10_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q11 · Tiga celah isolasi
**Penanggung jawab:** Mael · **Berkas:** `q11_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q12 · Perilaku normal rentan.py
**Penanggung jawab:** Azkha · **Berkas:** `q12_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q13 · Sebab injection, bukan kutip
**Penanggung jawab:** Azkha · **Berkas:** `q13_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q14 · Batas hak lewat app_laporan
**Penanggung jawab:** Azkha · **Berkas:** `q14_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q15 · Perbaikan berparameter
**Penanggung jawab:** Azkha · **Berkas:** `q15_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q16 · Pengenal dan daftar putih
**Penanggung jawab:** Azkha · **Berkas:** `q16_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q17 · Second-order injection
**Penanggung jawab:** Azkha · **Berkas:** `q17_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q18 · Batas waktu query
**Penanggung jawab:** Azkha · **Berkas:** `q18_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q19 · Hash vs enkripsi
**Penanggung jawab:** Syifa · **Berkas:** `q19_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q20 · Biaya kerja hash
**Penanggung jawab:** Syifa · **Berkas:** `q20_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q21 · Enkripsi kolom
**Penanggung jawab:** Syifa · **Berkas:** `q21_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q22 · Kunci bocor
**Penanggung jawab:** Syifa · **Berkas:** `q22_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q23 · Penyamaran
**Penanggung jawab:** Syifa · **Berkas:** `q23_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q24 · Identifikasi ulang
**Penanggung jawab:** Syifa · **Berkas:** `q24_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q25 · Tabel dan trigger audit
**Penanggung jawab:** Agi · **Berkas:** `q25_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q26 · Uji audit
**Penanggung jawab:** Agi · **Berkas:** `q26_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q27 · Sinyal anomali
**Penanggung jawab:** Agi · **Berkas:** `q27_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q28 · Permintaan hapus
**Penanggung jawab:** Agi · **Berkas:** `q28_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q29 · Hapus dan sisa data
**Penanggung jawab:** Agi · **Berkas:** `q29_*.sql`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

### Q30 · Peta UU PDP
**Penanggung jawab:** Agi · **Berkas:** `q30_*.md`

- **Peran yang menjalankan:** `...`
- **Perintah:** 
```sql
-- tempel perintah
```
- **Keluaran nyata:**
```text
-- tempel keluaran / pesan galat
```
- **Uji negatif (bila relevan):** ...
- **Alasan keputusan:** ...

## Refleksi A–E
### Refleksi A (Jelita)
Mengapa "mencabut hak" bukan jalan keluar K1, dan apa jalan keluarnya (bukti dari Q1):

### Refleksi B (Mael)
Apakah penyaring `WHERE tenant_id` di aplikasi masih perlu? Sebut rencana eksekusi (`EXPLAIN`):

### Refleksi C (Azkha)
Satu lapis yang menghapus sebab masalah, dan peran tiga lapis lain (bukti Q14 dan Q18):

### Refleksi D (Syifa)
Dua ancaman yang tetap terbuka dan satu risiko operasional enkripsi kolom (bukti Q21–Q24):

### Refleksi E (Agi)
Ketegangan Pasal 31 vs Pasal 43, dan satu usulan penyelesaian:

## Peta Tiket #1134 ke UU PDP
| Keluhan | Pasal relevan | Kontrol teknis pencegah | Bukti |
|---|---|---|---|
| K1 | | | |
| K2 | | | |
| K3 | | | |
| K4 | | | |
| K5 | | | |

*(Isi teks lima keluhan dari Tiket #1134. Detail lengkap di `q30_peta_uu_pdp.md`.)*

## R1 · Tiga Disiplin Keamanan
Tiap disiplin: lapisan penegakan, akibat bila dilanggar, satu bukti percobaan.

### 1. Hak akses (Jelita)
- Lapisan penegakan:
- Bila dilanggar:
- Bukti (Q...):

### 2. Isolasi data / RLS (Mael)
- Lapisan penegakan:
- Bila dilanggar:
- Bukti (Q...):

### 3. Kriptografi (Syifa)
- Lapisan penegakan:
- Bila dilanggar:
- Bukti (Q...):

## Pernyataan Etika
Seluruh percobaan serangan hanya dijalankan pada kontainer lab11 milik sendiri di jaringan tertutup yang tidak tersambung ke internet. Kami memahami bahwa menjalankannya pada sistem lain adalah tindak pidana.

| Nama | Tanda tangan | Tanggal |
|---|---|---|
| Jelita | | |
| Mael | | |
| Azkha | | |
| Syifa | | |
| Agi | | |

## Penggunaan AI dan Verifikasi
| Nama | Bagian yang dibantu AI | Cara memverifikasi (dijalankan ulang, dibandingkan dengan materi, dst.) |
|---|---|---|
| Jelita | | |
| Mael | | |
| Azkha | | |
| Syifa | | |
| Agi | | |