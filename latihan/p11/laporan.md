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
**Penanggung jawab:** Mael · **Berkas:** `q06_default_deny.sql`

- **Peran yang menjalankan:** `postgres` (untuk `ALTER TABLE`), lalu `app_laporan` lewat `SET LOCAL ROLE`
- **Perintah:**
```sql
ALTER TABLE lab11.pelanggan ENABLE ROW LEVEL SECURITY;

BEGIN;
  SET LOCAL ROLE app_laporan;
  SELECT current_user AS peran_aktif,
         count(*)     AS sebelum_ada_kebijakan
  FROM lab11.pelanggan;
COMMIT;
```
- **Keluaran nyata:**
```text
ALTER TABLE
BEGIN
SET
 peran_aktif | sebelum_ada_kebijakan 
-------------+-----------------------
 app_laporan |                     0
(1 row)

COMMIT
```
- **Uji negatif (bila relevan):** `app_laporan` mengembalikan `0` baris meskipun memiliki hak `SELECT` pada tabel `lab11.pelanggan`.
- **Alasan keputusan:** PostgreSQL menerapkan perilaku *default-deny* begitu RLS diaktifkan tanpa kebijakan. Jika administrator lupa membuat `CREATE POLICY`, basis data menolak seluruh baris daripada membocorkan data antar penyewa.

### Q7 · Kebijakan isolasi penyewa
**Penanggung jawab:** Mael · **Berkas:** `q07_kebijakan_penyewa.sql`

- **Peran yang menjalankan:** `postgres`
- **Perintah:**
```sql
CREATE POLICY p_tenant_baca ON lab11.pelanggan
  FOR SELECT TO app_read, app_write
  USING (tenant_id = nullif(current_setting('app.tenant', true), '')::int);

CREATE POLICY p_tenant_tulis ON lab11.pelanggan
  FOR ALL TO app_write
  USING      (tenant_id = nullif(current_setting('app.tenant', true), '')::int)
  WITH CHECK (tenant_id = nullif(current_setting('app.tenant', true), '')::int);

SELECT policyname, cmd, roles
FROM pg_policies
WHERE schemaname = 'lab11' AND tablename = 'pelanggan'
ORDER BY policyname;
```
- **Keluaran nyata:**
```text
CREATE POLICY
CREATE POLICY
   policyname   |  cmd   |        roles         
----------------+--------+----------------------
 p_tenant_baca  | SELECT | {app_read,app_write}
 p_tenant_tulis | ALL    | {app_write}
(2 rows)
```
- **Uji negatif (bila relevan):** Saat `app.tenant` belum disetel atau bernilai string kosong `''`, ekspresi `nullif(..., '')` menghasilkan `NULL` sehingga perbandingan `tenant_id = NULL` bernilai tidak diketahui dan tidak melempar galat sintaks integer.
- **Alasan keputusan:** Menggunakan `nullif(current_setting('app.tenant', true), '')::int` mencegah galat `invalid input syntax for type integer: ""` pada PostgreSQL 17 ketika koneksi dari *connection pool* dipakai ulang setelah konteks sebelumnya di-reset menjadi string kosong.

### Q8 · Uji positif dan negatif
**Penanggung jawab:** Mael · **Berkas:** `q08_uji_positif_negatif.sql`

- **Peran yang menjalankan:** `app_laporan` (dengan `SET LOCAL app.tenant = '1'`)
- **Perintah:**
```sql
BEGIN;
  SET LOCAL ROLE app_laporan;
  SET LOCAL app.tenant = '1';

  SELECT count(*) AS terlihat_tenant1
  FROM lab11.pelanggan;

  SELECT count(*) AS harus_nol
  FROM lab11.pelanggan
  WHERE tenant_id = 2;
COMMIT;
```
- **Keluaran nyata:**
```text
BEGIN
SET
SET
 terlihat_tenant1 
------------------
            10000
(1 row)

 harus_nol 
-----------
         0
(1 row)

COMMIT
```
- **Uji negatif (bila relevan):** Permintaan eksplisit `WHERE tenant_id = 2` sebagai penyewa 1 menghasilkan `0` baris karena predikat kebijakan `tenant_id = 1` otomatis disuntikkan oleh basis data.
- **Alasan keputusan:** Uji positif saja hanya membuktikan data bisa dibaca, sedangkan uji negatif membuktikan bahwa batas isolasi antar penyewa benar-benar ditegakkan bahkan ketika query aplikasi meminta data penyewa lain secara langsung.

### Q9 · FORCE RLS dan BYPASSRLS
**Penanggung jawab:** Mael · **Berkas:** `q09_force_dan_bypass.sql`

- **Peran yang menjalankan:** `postgres` (DDL/DCL), `skema_owner`, dan `app_analitik`
- **Perintah:**
```sql
BEGIN;
  SET LOCAL ROLE skema_owner;
  SELECT count(*) AS owner_sebelum_force FROM lab11.pelanggan;
COMMIT;

ALTER TABLE lab11.pelanggan FORCE ROW LEVEL SECURITY;

BEGIN;
  SET LOCAL ROLE skema_owner;
  SELECT count(*) AS owner_sesudah_force FROM lab11.pelanggan;
COMMIT;

GRANT pg_read_all_data TO app_analitik;
BEGIN;
  SET LOCAL ROLE app_analitik;
  SELECT count(*) AS analitik_dengan_read_all FROM lab11.pelanggan;
COMMIT;

ALTER ROLE app_analitik BYPASSRLS;
BEGIN;
  SET LOCAL ROLE app_analitik;
  SELECT count(*) AS analitik_dengan_bypassrls FROM lab11.pelanggan;
COMMIT;

ALTER ROLE app_analitik NOBYPASSRLS;
REVOKE pg_read_all_data FROM app_analitik;
```
- **Keluaran nyata:**
```text
 owner_sebelum_force 
---------------------
               30000

 owner_sesudah_force 
---------------------
                   0

 analitik_dengan_read_all 
--------------------------
                        0

 analitik_dengan_bypassrls 
---------------------------
                     30000
```
- **Uji negatif (bila relevan):** Setelah `FORCE ROW LEVEL SECURITY`, `skema_owner` tanpa konteks penyewa melihat `0` baris; `app_analitik` dengan `pg_read_all_data` juga melihat `0` baris.
- **Alasan keputusan:** Secara bawaan pemilik tabel dikecualikan dari RLS, sehingga `FORCE ROW LEVEL SECURITY` wajib dipasang. Percobaan juga membuktikan bahwa `pg_read_all_data` hanya memberi hak `SELECT` tingkat tabel dan tidak membawa `BYPASSRLS`, sedangkan atribut `BYPASSRLS` meruntuhkan seluruh isolasi baris sehingga tidak boleh diberikan ke peran aplikasi maupun analis.

### Q10 · Kolam koneksi
**Penanggung jawab:** Mael · **Berkas:** `q10_kolam_koneksi.sql`

- **Peran yang menjalankan:** `postgres` dan `app_laporan` pada satu koneksi session yang sama
- **Perintah:**
```sql
-- Salah (SET tanpa LOCAL):
SET app.tenant = '1';
BEGIN;
  SET LOCAL ROLE app_laporan;
  SELECT current_setting('app.tenant', true) AS konteks_tertinggal,
         count(*) AS baris_bocor_ke_penyewa2
  FROM lab11.pelanggan;
COMMIT;

RESET app.tenant;

-- Benar (set_config dengan is_local = true):
BEGIN;
  SELECT set_config('app.tenant', '1', true);
  SET LOCAL ROLE app_laporan;
  SELECT count(*) AS akses_sah_penyewa1 FROM lab11.pelanggan;
COMMIT;

BEGIN;
  SET LOCAL ROLE app_laporan;
  SELECT coalesce(nullif(current_setting('app.tenant', true), ''), '<kosong>') AS konteks_setelah_commit,
         count(*) AS baris_terlihat_penyewa2
  FROM lab11.pelanggan;
COMMIT;
```
- **Keluaran nyata:**
```text
 konteks_tertinggal | baris_bocor_ke_penyewa2 
--------------------+-------------------------
 1                  |                   10000

 akses_sah_penyewa1 
--------------------
              10000

 konteks_setelah_commit | baris_terlihat_penyewa2 
------------------------+-------------------------
 <kosong>               |                       0
```
- **Uji negatif (bila relevan):** Setelah `COMMIT` pada pola `set_config(..., true)`, permintaan berikutnya yang lupa menyetel konteks mendapat nilai `<kosong>` dan `0` baris (gagal aman).
- **Alasan keputusan:** Pada arsitektur *connection pooling*, koneksi fisik dipakai bergantian antar penyewa. Penggunaan `SET` biasa meninggalkan nilai di level sesi sehingga bocor ke permintaan berikutnya, sedangkan `SET LOCAL` atau `set_config(..., true)` membatasi umur variabel hanya di dalam transaksi dan otomatis bersih saat transaksi berakhir.

### Q11 · Tiga celah isolasi
**Penanggung jawab:** Mael · **Berkas:** `q11_tiga_celah.sql`

- **Peran yang menjalankan:** `postgres` dan `app_portal` (dalam transaksi `ROLLBACK`)
- **Perintah:**
```sql
BEGIN;
  CREATE POLICY p_impor_longgar ON lab11.pelanggan
    FOR INSERT TO app_write
    WITH CHECK (true);

  SET LOCAL ROLE app_portal;
  SET LOCAL app.tenant = '1';

  INSERT INTO lab11.pelanggan (id, tenant_id, nama, nik, surel, lahir, kota, saldo, rekening, dibuat_pada)
  VALUES (99999, 2, 'Penyusup Tenant 2', '1271000000099999', 'susup@contoh.test',
          DATE '1995-05-05', 'Medan', 500000, '9999999999', now());

  SELECT count(*) AS terlihat_oleh_penyewa1
  FROM lab11.pelanggan
  WHERE id = 99999;
ROLLBACK;
```
- **Keluaran nyata:**
```text
BEGIN
CREATE POLICY
SET
SET
INSERT 0 1
 terlihat_oleh_penyewa1 
------------------------
                      0
(1 row)

ROLLBACK
```
- **Uji negatif (bila relevan):** Baris dengan `tenant_id = 2` berhasil disisipkan oleh penyewa 1 (`INSERT 0 1`), walau tidak terlihat oleh penyewa 1 sendiri (`0` baris).
- **Alasan keputusan:** Tiga cara isolasi RLS masih bisa gagal beserta perbaikannya:
  1. **Kebijakan permisif tambahan yang terlalu longgar** (misalnya `FOR INSERT WITH CHECK (true)` untuk impor): PostgreSQL menggabungkan seluruh kebijakan permisif dengan logika `OR` sehingga kebijakan longgar membatalkan kebijakan ketat; perbaikannya adalah mengganti ekspresi `true` dengan pemeriksaan `tenant_id` yang sah atau menggunakan kebijakan `RESTRICTIVE`.
  2. **Kebocoran konteks penyewa di kolam koneksi atau penyetelan `app.tenant` dari input tak tervalidasi**: Jika aplikasi memakai `SET` tanpa `LOCAL` atau mengambil nilai dari klien tanpa validasi token sesi sisi server, penyewa dapat menyamar; perbaikannya adalah selalu menyetel konteks menggunakan `set_config('app.tenant', ..., true)` dari klaim sesi terautentikasi.
  3. **Akses melalui `VIEW` tanpa `security_invoker` atau fungsi `SECURITY DEFINER` milik pemilik objek**: Keduanya berjalan dengan hak pemilik objek (bukan pemanggil) sehingga kebijakan RLS peran aplikasi dapat dilewati; perbaikannya adalah mengaktifkan `security_invoker = true` pada *view* penyewa dan menghindari `SECURITY DEFINER` untuk query data multi-penyewa.

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

**Ya, penyaring `WHERE tenant_id` di aplikasi tetap perlu ditulis**, meskipun RLS sudah aktif di basis data. Keduanya memikul tugas yang berbeda dalam arsitektur pertahanan berlapis:
1. **Tugas RLS (Batas Keamanan / *Security Boundary*):** Ditegakkan oleh basis data sebagai jaring pengaman wajib (*fail-safe*) agar data lintas penyewa tidak pernah bocor sekalipun pengembang lupa menulis klausa `WHERE` atau terjadi celah pada kode aplikasi.
2. **Tugas `WHERE tenant_id` di Aplikasi (Kejelasan Niat & Optimasi Rencana Eksekusi):** Menyatakan niat bisnis secara eksplisit dan membantu perencana query (*query planner*) PostgreSQL dalam menyusun rencana eksekusi (`EXPLAIN`). Ketika predikat `WHERE tenant_id = <konstanta>` ditulis langsung oleh aplikasi, *planner* dapat melakukan pemangkasan partisi (*partition pruning*) maupun pemilihan indeks (*Index Scan*) secara langsung saat tahap perencanaan. Sebaliknya, jika hanya mengandalkan ekspresi dinamis `nullif(current_setting('app.tenant', true), '')::int` dari RLS, nilai parameter sesi sering kali baru dievaluasi saat eksekusi sehingga berisiko menurunkan efisiensi pemilihan indeks pada tabel besar.
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
- **Lapisan penegakan:** Lapisan mesin basis data (PostgreSQL) pada tingkat baris tabel melalui `ENABLE/FORCE ROW LEVEL SECURITY` dan `CREATE POLICY` (`USING` dan `WITH CHECK`).
- **Bila dilanggar:** Query yang melanggar predikat kebijakan tidak membocorkan data penyewa lain—operasi pembacaan (`SELECT`) otomatis menyaring baris menjadi `0` hasil, sedangkan operasi penulisan (`INSERT`/`UPDATE`) yang melanggar `WITH CHECK` langsung ditolak dengan galat `new row violates row-level security policy`.
- **Bukti (Q8 & Q9):** Pada Q8, `app_laporan` penyewa 1 yang secara eksplisit meminta `WHERE tenant_id = 2` hanya menerima `0` baris, sementara data miliknya sendiri (`10.000` baris) tetap terbaca penuh. Pada Q9, setelah `FORCE ROW LEVEL SECURITY` diaktifkan, bahkan pemilik tabel (`skema_owner`) tanpa konteks penyewa tersaring menjadi `0` baris.

### 3. Kriptografi (Syifa)
- Lapisan penegakan:
- Bila dilanggar:
- Bukti (Q...):

## Pernyataan Etika
Seluruh percobaan serangan hanya dijalankan pada kontainer lab11 milik sendiri di jaringan tertutup yang tidak tersambung ke internet. Kami memahami bahwa menjalankannya pada sistem lain adalah tindak pidana.

| Nama                       | Tanda tangan | Tanggal |
|----------------------------|--------------|---------|
| Jelita Hati Sinurat        |              |         |
| M. Dzakwan Ismail Rangkuti |M. Dzakwan Ismail Rangkuti | 18 November 2026 |
| Agi Aginta Sembiring       |              |         |
| M. Azkha Amorie            |              |         |
| Syifa Nazira               |              |         |

## Penggunaan AI dan Verifikasi
| Nama                      -| Bagian yang dibantu AI | Cara memverifikasi (dijalankan ulang, dibandingkan dengan materi, dst.) |
|----------------------------|------------------------|-------------------------------------------------------------------------|
| Jelita Hati Sinurat        |                        |                                                                         |
| M. Dzakwan Ismail Rangkuti | Penyusunan skrip pengujian RLS Q6–Q11 dan perumusan analisis Refleksi B | Menjalankan langsung seluruh skrip q06–q11 di kontainer lab11-db jaringan tertutup, memverifikasi angka keluaran (0 vs 10.000 vs 30.000 baris), dan mencocokkan dengan materi segmen 03. | 
| Agi Aginta Sembiring       |                        |                                                                         |
| M. Azkha Amorie            |                        |                                                                         |
| Syifa Nazira               |                        |                                                                         |