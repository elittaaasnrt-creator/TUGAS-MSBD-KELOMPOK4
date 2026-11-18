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
Peran: `postgres`. Setup lab11 dibuat sendiri oleh kelompok karena berkas modul tidak ditemukan.

```text
 tenant | pelanggan | akun | transaksi
--------+-----------+------+-----------
      3 |     30000 |    4 |    120000

 tenant_id | count
-----------+-------
         1 | 10000
         2 | 10000
         3 | 10000

docker network inspect lab11_labnet --format '{{.Internal}}'  ->  true
lab11-db  Up (healthy)  5432/tcp   (tanpa port publik)
```
## Q1–Q30
Format tiap soal: peran, perintah, keluaran nyata, uji negatif, alasan keputusan.

### Q1 · Hak pemilik tidak bisa dicabut
**Penanggung jawab:** Jelita · **Berkas:** `q01_*.sql`

- **Peran yang menjalankan:** `postgres` (REVOKE), lalu `skema_owner` lewat `SET ROLE` (UPDATE dan GRANT)
- **Perintah:**
```sql
REVOKE UPDATE ON lab11.pelanggan FROM skema_owner;
SET ROLE skema_owner;
BEGIN; UPDATE lab11.pelanggan SET kota = kota WHERE id = 3; ROLLBACK;
GRANT UPDATE ON lab11.pelanggan TO skema_owner;
BEGIN; UPDATE lab11.pelanggan SET kota = kota WHERE id = 3; ROLLBACK;
RESET ROLE;
```
- **Keluaran nyata:**
```text
ERROR:  permission denied for table pelanggan     (UPDATE pertama, setelah REVOKE)
UPDATE 1                                           (UPDATE kedua, setelah GRANT oleh pemilik sendiri)
```
- **Uji negatif (bila relevan):** UPDATE pertama ditolak, jadi REVOKE memang berlaku, tetapi hanya sampai pemilik memberikannya lagi.
- **Alasan keputusan:** Pemilik objek memegang semua hak beserta wewenang menggrantnya. REVOKE hanya menghapus entri di ACL, sedangkan wewenang itu melekat pada kepemilikan, sehingga pemilik bisa memulihkan haknya sendiri kapan saja.

### Q2 · DROP bukan hak yang bisa di-REVOKE
**Penanggung jawab:** Jelita · **Berkas:** `q02_*.sql`

- **Peran yang menjalankan:** `postgres`
- **Perintah:**
```sql
REVOKE DROP ON lab11.akun FROM skema_owner;
```
- **Keluaran nyata:**
```text
ERROR:  unrecognized privilege type "drop"
```
- **Uji negatif (bila relevan):** DROP tidak dikenali sebagai hak, jadi tidak ada yang bisa dicabut.
- **Alasan keputusan:** SELECT/UPDATE adalah hak di ACL yang bisa diberi dan dicabut. DROP dan ALTER adalah wewenang yang melekat pada pemilik (atau anggota peran pemilik dan superuser). Satu-satunya jalan mencabutnya adalah memindahkan kepemilikan (`ALTER ... OWNER TO`) atau menghapus peran.

### Q3 · Default privileges
**Penanggung jawab:** Jelita · **Berkas:** `q03_*.sql`

- **Peran yang menjalankan:** `postgres`
- **Perintah:**
```sql
CREATE TABLE lab11.catatan_postgres (id int);
SELECT has_table_privilege('app_laporan','lab11.catatan_postgres','SELECT') AS via_postgres;
DROP TABLE lab11.catatan_postgres;
```
- **Keluaran nyata:**
```text
 via_postgres
--------------
 f
```
- **Uji negatif (bila relevan):** `app_laporan` tidak bisa membaca tabel buatan `postgres` (hasil `f`).
- **Alasan keputusan:** `ALTER DEFAULT PRIVILEGES FOR ROLE skema_owner` hanya berlaku untuk objek yang dibuat `skema_owner`. Untuk objek buatan `postgres` perlu `ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA lab11 GRANT SELECT ON TABLES TO app_laporan;` (berlaku untuk objek baru, tidak retroaktif).

### Q4 · GRANT OPTION dan CASCADE
**Penanggung jawab:** Jelita · **Berkas:** `q04_*.sql`

- **Peran yang menjalankan:** `postgres`, dan `app_write` lewat `SET ROLE` untuk meneruskan hak
- **Perintah:**
```sql
GRANT SELECT ON lab11.transaksi TO app_write WITH GRANT OPTION;
SET ROLE app_write;
GRANT SELECT ON lab11.transaksi TO app_analitik;
RESET ROLE;
REVOKE GRANT OPTION FOR SELECT ON lab11.transaksi FROM app_write;
REVOKE GRANT OPTION FOR SELECT ON lab11.transaksi FROM app_write CASCADE;
SELECT has_table_privilege('app_analitik','lab11.transaksi','SELECT') AS analitik,
       has_table_privilege('app_write','lab11.transaksi','SELECT')    AS app_write;
```
- **Keluaran nyata:**
```text
ERROR:  dependent privileges exist
HINT:  Use CASCADE to revoke them too.
(REVOKE ... CASCADE berhasil)
 analitik | app_write
----------+-----------
 f        | t
```
- **Uji negatif (bila relevan):** setelah CASCADE, `app_analitik` kehilangan akses (`f`).
- **Alasan keputusan:** Hak `app_analitik` diturunkan lewat `app_write`, jadi tanpa CASCADE PostgreSQL menolak agar tidak ada hak yatim. `REVOKE GRANT OPTION FOR` (bukan `REVOKE SELECT`) dipilih supaya SELECT milik `app_write` tetap utuh (`t`).

### Q5 · Tabel tujuh peran
**Penanggung jawab:** Jelita · **Berkas:** `q05_*.sql`

- **Peran yang menjalankan:** `postgres`
- **Perintah:**
```sql
SELECT rolname, rolcanlogin AS bisa_login, rolsuper, rolbypassrls
FROM pg_roles WHERE rolname LIKE 'app\_%' OR rolname = 'skema_owner' ORDER BY 1;
SELECT r.rolname AS peran, m.rolname AS anggota_dari
FROM pg_auth_members a JOIN pg_roles r ON r.oid = a.member JOIN pg_roles m ON m.oid = a.roleid
WHERE r.rolname LIKE 'app\_%' ORDER BY 1;
```
- **Keluaran nyata:**
```text
   rolname    | bisa_login | rolsuper | rolbypassrls
 app_analitik | t          | f        | f
 app_auditor  | t          | f        | f
 app_laporan  | t          | f        | f
 app_portal   | t          | f        | f
 app_read     | f          | f        | f
 app_write    | f          | f        | f
 skema_owner  | f          | f        | f
 keanggotaan: app_laporan -> app_read, app_portal -> app_write
```

| Peran | Login | Boleh melakukan |
|---|---|---|
| skema_owner | tidak | pemilik skema dan tabel lab11: DDL dan GRANT; tidak dipakai aplikasi |
| app_read | tidak | SELECT pada pelanggan (tunduk RLS), dipakai lewat keanggotaan |
| app_write | tidak | SELECT/INSERT/UPDATE/DELETE pada pelanggan (tunduk RLS) |
| app_laporan | ya | anggota app_read; baca laporan; SELECT otomatis pada tabel baru skema_owner |
| app_analitik | ya | tanpa hak awal; nanti hanya membaca tampilan tersamar |
| app_portal | ya | anggota app_write; aplikasi portal penyewa |
| app_auditor | ya | tanpa hak awal; disiapkan untuk membaca jejak audit |

- **Uji negatif (bila relevan):** tidak ada peran superuser atau BYPASSRLS selain `postgres`.
- **Alasan keputusan:** Aplikasi tidak pernah login sebagai pemilik karena hak pemilik (DROP, ALTER, GRANT) tidak bisa dicabut, sehingga satu celah injection akan menyerahkan seluruh skema.

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

Pada Q1, `REVOKE UPDATE` memang membuat `skema_owner` ditolak (`ERROR: permission denied for table pelanggan`), tetapi satu `GRANT UPDATE` yang dijalankan pemilik sendiri langsung memulihkannya (`UPDATE 1`). Q2 menambah bukti bahwa DROP dan ALTER bahkan bukan hak yang bisa dicabut (`unrecognized privilege type "drop"`). Jadi risikonya melekat pada kepemilikan, bukan pada daftar hak, dan mencabut hak hanya menutup pintu yang kuncinya masih dipegang pemilik. Itu sebabnya "mencabut hak" bukan jalan keluar untuk K1. Jalan keluarnya adalah memisahkan peran: pemilik tidak pernah dipakai login aplikasi (hanya untuk migrasi), aplikasi memakai peran `app_*` non-pemilik dengan hak minimum per tabel (Q5), `ALTER DEFAULT PRIVILEGES` untuk objek baru (Q3), dan `FORCE ROW LEVEL SECURITY` supaya pemilik pun tunduk pada kebijakan.
### Refleksi B (Mael)
Apakah penyaring `WHERE tenant_id` di aplikasi masih perlu? Sebut rencana eksekusi (`EXPLAIN`):

### Refleksi C (Azkha)
Satu lapis yang menghapus sebab masalah, dan peran tiga lapis lain (bukti Q14 dan Q18):

### Refleksi D (Agi)
Dua ancaman yang tetap terbuka dan satu risiko operasional enkripsi kolom (bukti Q21–Q24):

### Refleksi E (Syifa)
Ketegangan Pasal 31 vs Pasal 43, dan satu usulan penyelesaian:

Pasal 31 UU No. 27 Tahun 2022 mewajibkan Pengendali Data Pribadi untuk merekam seluruh kegiatan pemrosesan data pribadi (yang secara teknis diwujudkan melalui tabel `jejak_audit`), sedangkan Pasal 43 memberikan hak kepada Subjek Data Pribadi untuk meminta penghapusan dan pemusnahan data pribadinya. Ketegangan muncul pada percobaan Q29: ketika baris pelanggan dihapus dari tabel utama (`sisa_tabel_utama = 0`), trigger `rekam_audit` justru menyimpan salinan lengkap baris sebelum dihapus (`to_jsonb(OLD)`) ke kolom `nilai_lama` pada `jejak_audit`, sehingga identitas sensitif seperti `nik` tetap bertahan (`sisa_jejak_audit = 2`).

**Usulan penyelesaian:** Menerapkan **pseudonimisasi dan redaksi selektif pada catatan audit** (*crypto-shredding* atau penghapusan atribut pengenal langsung di kolom `nilai_lama`/`nilai_baru`). Alih-alih menyimpan `nik`, `surel`, atau `rekening` secara mentah di dalam JSONB audit, fungsi trigger hanya mencatat kolom non-pengenal atau nilai hash/token dari `id` pelanggan, serta menjalankan prosedur pembersihan atribut sensitif (`nilai_lama - 'nik' - 'surel' - 'rekening'`) pada `jejak_audit` saat permintaan penghapusan Pasal 43 dieksekusi. Dengan demikian, metadata audit (siapa melakukan aksi apa, kapan, dan pada kunci token berapa) tetap utuh untuk memenuhi akuntabilitas Pasal 31 tanpa menyimpan data pribadi yang dapat mengidentifikasi subjek secara langsung setelah hak hapus Pasal 43 dipenuhi.


## Peta Tiket #1134 ke UU PDP
| Keluhan | Pasal relevan | Kontrol teknis pencegah | Bukti |
|---|---|---|---|
| **K1:** Akun aplikasi berjalan dengan hak terlalu tinggi (setara pemilik objek) sehingga berisiko mengubah struktur tabel maupun memanipulasi data secara tidak sah. | Pasal 35 & Pasal 39 UU No. 27 Tahun 2022 | Pemisahan peran (*least privilege*): aplikasi dilarang login sebagai `skema_owner` dan wajib memakai peran non-pemilik (`app_portal`, `app_laporan`) dengan hak minimum per tabel serta `ALTER DEFAULT PRIVILEGES`. | **Q1–Q5**: `REVOKE` pada `skema_owner` tetap bisa dipulihkan sendiri (`UPDATE 1`), sehingga aplikasi diwajibkan memakai peran `app_*` non-pemilik. |
| **K2:** Terjadi aktivitas pembacaan atau perubahan data massal yang mencurigakan di luar jam kerja operasional tanpa terdeteksi. | Pasal 31 & Pasal 39 UU No. 27 Tahun 2022 | Trigger audit otomatis `SECURITY DEFINER` (`rekam_audit`) memakai `session_user` ke tabel `jejak_audit` yang terkunci dari peran aplikasi, dilengkapi kueri deteksi anomali lonjakan baris dan akses luar jam kerja (`Asia/Jakarta`). | **Q25–Q27**: Trigger merekam `pelaku = 'app_portal'`, upaya `DELETE` audit oleh `app_portal` ditolak (`permission denied`), dan kueri Q27 menyaring anomali jam kerja/lonjakan. |
| **K3:** Data pelanggan antar-penyewa (*tenant*) dapat saling terlihat atau bocor melalui kueri aplikasi. | Pasal 16 ayat (2) huruf e & Pasal 35 UU No. 27 Tahun 2022 | Penerapan *Row-Level Security* (`ENABLE` & `FORCE ROW LEVEL SECURITY`) pada `lab11.pelanggan` dengan kebijakan berbasis variabel sesi `nullif(current_setting('app.tenant', true), '')::int`. | **Q6–Q9**: Sebelum kebijakan dibuat hasil `0` baris (*default deny*); saat `app.tenant = '1'`, kueri ke `tenant_id = 2` menghasilkan `0` baris. |
| **K4:** Data pribadi sensitif (NIK, nomor rekening, saldo, dan kata sandi) tersimpan dalam bentuk teks terang tanpa pengamanan. | Pasal 35 & Pasal 36 UU No. 27 Tahun 2022 | Hashing kata sandi dengan `crypt(..., gen_salt('bf', 8))`, enkripsi kolom `rekening` dengan `pgp_sym_encrypt`, serta penyamaran NIK/surel/saldo lewat *security barrier view* (`v_pelanggan_samar`) untuk `app_analitik`. | **Q19–Q23**: Hash bcrypt menghasilkan *ciphertext* unik tiap dijalankan, dan `app_analitik` hanya dapat membaca NIK tersamar (`xxxxxxxxxxxx1234`). |
| **K5:** Subjek data meminta penghapusan datanya, namun salinan identitas (NIK) masih tertinggal di dalam log audit sistem. | Pasal 43 & Pasal 44 UU No. 27 Tahun 2022 | Pencatatan antrean pemenuhan hak hapus pada tabel `permintaan_hapus` bertenggat 72 jam (`DEFAULT now() + interval '72 hours'`), penghapusan berjenjang (`transaksi` lalu `pelanggan`), serta redaksi atribut sensitif pada payload JSONB audit. | **Q28–Q29**: `sisa_tabel_utama = 0` dan `sisa_transaksi = 0`, namun `sisa_jejak_audit = 2` karena `nilai_lama` masih menyimpan salinan NIK lama. |

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