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
**Penanggung jawab:** Agi · **Berkas:** `q12_perilaku_normal.sql`

- **Peran yang menjalankan:** `postgres` (default koneksi `rentan.py` di dalam kontainer `lab11-web`)
- **Perintah:**
```bash
python rentan.py "Pelanggan 12"
```
```sql
SELECT count(*) AS baris_normal
FROM lab11.pelanggan
WHERE tenant_id = 1 AND nama ILIKE '%Pelanggan 12%';
```
- **Keluaran nyata:**
```text
SQL: SELECT id, nama, kota FROM lab11.pelanggan WHERE tenant_id = 1 AND nama ILIKE '%Pelanggan 12%'
                                                                               ^^^^^^^^^^^^
                                                                     Bagian dari masukan pengguna
111 baris
```
- **Uji negatif (bila relevan):** Pada masukan normal `"Pelanggan 12"`, struktur sintaks query tetap utuh dan hanya mencocokkan nama pelanggan pada penyewa 1 (`Pelanggan 12`, `120–129`, dan `1200–1299` = `111` baris).
- **Alasan keputusan:** Menetapkan pembanding perilaku normal diperlukan untuk menunjukkan posisi tepat di mana masukan pengguna disisipkan secara mentah ke dalam string perintah SQL.

### Q13 · Sebab injection, bukan kutip
**Penanggung jawab:** Agi · **Berkas:** `q13_sebab_bukan_kutip.sql`

- **Peran yang menjalankan:** `postgres` (lewat `rentan.py` di `lab11-web`)
- **Perintah:**
```bash
python rentan.py "zz' OR '1'='1"
python rentan.py "zz' OR '1'='1' --"
```
```sql
SELECT count(*) AS payload_tanpa_komentar
FROM lab11.pelanggan
WHERE tenant_id = 1 AND nama ILIKE '%zz' OR '1'='1%';

SELECT count(*) AS payload_dengan_komentar
FROM lab11.pelanggan
WHERE tenant_id = 1 AND nama ILIKE '%zz' OR '1'='1' --%';
```
- **Keluaran nyata:**
```text
-- Payload 1 (tanpa --):
SQL: SELECT id, nama, kota FROM lab11.pelanggan WHERE tenant_id = 1 AND nama ILIKE '%zz' OR '1'='1%'
0 baris

-- Payload 2 (dengan --):
SQL: SELECT id, nama, kota FROM lab11.pelanggan WHERE tenant_id = 1 AND nama ILIKE '%zz' OR '1'='1' --%'
30000 baris
```
- **Uji negatif (bila relevan):** Pada payload pertama tanpa `--`, tanda kutip dan `%` di ujung menempel sehingga menjadi `'1'='1%'` (`FALSE`) dan mengembalikan `0` baris.
- **Alasan keputusan:** Pada payload kedua, komentar `--` membuang sisa kutip dan `%` di ujung sehingga `'1'='1'` menjadi `TRUE`. Karena prioritas operator `AND` lebih tinggi daripada `OR`, query dievaluasi sebagai `(tenant_id = 1 AND nama ILIKE '%zz') OR ('1'='1')`, yang melewati penyaring penyewa dan membocorkan seluruh `30.000` baris lintas penyewa. Ini membuktikan akar masalahnya adalah penyatuan saluran perintah dan data, bukan sekadar karakter kutip.

### Q14 · Batas hak lewat app_laporan
**Penanggung jawab:** Agi · **Berkas:** `q14_batas_hak.sql`

- **Peran yang menjalankan:** `app_laporan` (anggota `app_read` dengan konteks penyewa 1)
- **Perintah:**
```bash
DB_USER=app_laporan DB_PASS=lab11 python rentan.py "zz' OR '1'='1' --"
DB_USER=app_laporan DB_PASS=lab11 python rentan.py "zz' UNION SELECT id, username, kata_sandi FROM lab11.akun --"
```
```sql
BEGIN;
  SET LOCAL ROLE app_laporan;
  SET LOCAL app.tenant = '1';
  SELECT count(*) AS baris_via_app_laporan
  FROM lab11.pelanggan
  WHERE tenant_id = 1 AND nama ILIKE '%zz' OR '1'='1'; --%';
COMMIT;
```
- **Keluaran nyata:**
```text
-- Payload OR '1'='1' via app_laporan:
SQL: SELECT id, nama, kota FROM lab11.pelanggan WHERE tenant_id = 1 AND nama ILIKE '%zz' OR '1'='1' --%'
10000 baris

-- Payload UNION SELECT ke lab11.akun via app_laporan:
psycopg2.errors.InsufficientPrivilege: permission denied for table akun
```
- **Uji negatif (bila relevan):** Serangan `UNION SELECT` ke tabel `lab11.akun` ditolak (`permission denied for table akun`), dan kebocoran pada `lab11.pelanggan` tertahan hanya pada `10.000` baris penyewa 1.
- **Alasan keputusan:** Prinsip hak minimum per tabel dan kebijakan RLS berhasil membatasi radius ledakan serangan (tabel `akun` terlindungi dan data penyewa 2–3 tidak bocor), tetapi selama query masih dirangkai dengan penyambungan string, penyerang tetap bisa menyedot seluruh `10.000` data di dalam penyewa yang sama.

### Q15 · Perbaikan berparameter
**Penanggung jawab:** Agi · **Berkas:** `q15_perbaikan.sql`, `rentan.py`

- **Peran yang menjalankan:** `app_laporan` (lewat `rentan.py` yang sudah diubah ke `cari_aman`)
- **Perintah:**
```bash
DB_USER=app_laporan DB_PASS=lab11 python rentan.py "zz' OR '1'='1' --"
DB_USER=app_laporan DB_PASS=lab11 python rentan.py "Pelanggan 12"
```
```sql
PREPARE q_cari_aman (text) AS
  SELECT count(*) AS hasil_berparameter
  FROM lab11.pelanggan
  WHERE tenant_id = 1 AND nama ILIKE $1;

EXECUTE q_cari_aman('%zz'' OR ''1''=''1'' --%');
DEALLOCATE q_cari_aman;
```
- **Keluaran nyata:**
```text
0 baris (aman)
100 baris (aman)
```
- **Uji negatif (bila relevan):** Seluruh payload `zz' OR '1'='1' --` diperlakukan murni sebagai teks pencarian literal sehingga menghasilkan `0 baris (aman)`.
- **Alasan keputusan:** Query berparameter (*prepared statement* dengan placeholder `%s`) memisahkan struktur sintaks perintah dari nilai parameter pada protokol komunikasi basis data. Penyaringan atau penghapusan karakter kutip (*blacklist sanitization*) tidak akan mencapai keamanan yang setara karena mudah dilewati melalui variasi *encoding*, injeksi tanpa kutip, maupun komentar, sekaligus merusak masukan sah yang memang mengandung apostrof.

### Q16 · Pengenal dan daftar putih
**Penanggung jawab:** Agi · **Berkas:** `q16_pengenal_daftar_putih.sql`

- **Peran yang menjalankan:** `postgres`
- **Perintah:**
```sql
DO $$
DECLARE
  v_kolom text := 'kota';
  v_arah  text := 'DESC';
  v_sql   text;
  v_contoh text;
BEGIN
  IF v_kolom NOT IN ('nama', 'kota', 'dibuat_pada') OR v_arah NOT IN ('ASC', 'DESC') THEN
    RAISE EXCEPTION 'parameter pengurutan tidak dikenal: % %', v_kolom, v_arah;
  END IF;
  v_sql := format(
    'SELECT nama || '' ('' || kota || '')'' FROM lab11.pelanggan WHERE tenant_id = 1 ORDER BY %I %s LIMIT 1',
    v_kolom, v_arah
  );
  EXECUTE v_sql INTO v_contoh;
  RAISE NOTICE 'Validasi daftar putih berhasil -> contoh baris: %', v_contoh;
END $$;

-- Uji negatif (nilai di luar daftar putih):
DO $$
DECLARE
  v_kolom text := 'nama; DROP TABLE lab11.pelanggan; --';
BEGIN
  IF v_kolom NOT IN ('nama', 'kota', 'dibuat_pada') THEN
    RAISE EXCEPTION 'parameter pengurutan tidak dikenal: %', v_kolom;
  END IF;
END $$;
```
- **Keluaran nyata:**
```text
NOTICE:  Validasi daftar putih berhasil -> contoh baris: Pelanggan 3 (Rantauprapat)
ERROR:  parameter pengurutan tidak dikenal: nama; DROP TABLE lab11.pelanggan; --
CONTEXT:  PL/pgSQL function inline_code_block line 7 at RAISE
```
- **Uji negatif (bila relevan):** Masukan pengurutan di luar daftar putih (`nama; DROP TABLE lab11.pelanggan; --`) langsung ditolak sebelum menyentuh penyusunan query.
- **Alasan keputusan:** Parameter berikat (`%s` / `$1`) hanya berlaku untuk nilai literal, bukan nama kolom, nama tabel, atau kata kunci arah urut (`ASC`/`DESC`). Karena pengenal tidak dapat diparameterkan, satu-satunya cara aman adalah memetakannya melalui daftar putih tertutup (*whitelist*) di aplikasi dan membungkus pengenal dengan `format('%I', ...)` di SQL.

### Q17 · Second-order injection
**Penanggung jawab:** Agi · **Berkas:** `q17_second_order.sql`

- **Peran yang menjalankan:** `postgres` (dalam transaksi `ROLLBACK`)
- **Perintah:**
```sql
CREATE OR REPLACE FUNCTION lab11.laporan_kota_rentan(p_transaksi_id int)
RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE v_status text; v_total bigint;
BEGIN
  SELECT status INTO v_status FROM lab11.transaksi WHERE id = p_transaksi_id;
  EXECUTE 'SELECT count(*) FROM lab11.transaksi t JOIN lab11.pelanggan p ON p.id = t.pelanggan_id WHERE t.status = ''' || v_status || '''' INTO v_total;
  RETURN v_total;
END $$;

CREATE OR REPLACE FUNCTION lab11.laporan_kota_aman(p_transaksi_id int)
RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE v_status text; v_total bigint;
BEGIN
  SELECT status INTO v_status FROM lab11.transaksi WHERE id = p_transaksi_id;
  EXECUTE 'SELECT count(*) FROM lab11.transaksi t JOIN lab11.pelanggan p ON p.id = t.pelanggan_id WHERE t.status = $1' USING v_status INTO v_total;
  RETURN v_total;
END $$;

BEGIN;
  PREPARE ins_transaksi_aman (int, int, int, numeric, text) AS
    INSERT INTO lab11.transaksi (id, pelanggan_id, tenant_id, jumlah, status, dibuat_pada)
    VALUES ($1, $2, $3, $4, $5, now());
  EXECUTE ins_transaksi_aman(999999, 1, 1, 50000, ''' OR ''1''=''1');
  DEALLOCATE ins_transaksi_aman;

  SELECT lab11.laporan_kota_rentan(999999) AS hasil_laporan_rentan,
         lab11.laporan_kota_aman(999999)   AS hasil_laporan_aman;
ROLLBACK;
```
- **Keluaran nyata:**
```text
CREATE FUNCTION
CREATE FUNCTION
INSERT 0 1
 hasil_laporan_rentan | hasil_laporan_aman 
----------------------+--------------------
               120001 |                  1
ROLLBACK
```
- **Uji negatif (bila relevan):** `laporan_kota_rentan` mengembalikan `120001` baris (seluruh isi tabel `transaksi` ditambah baris uji) meskipun data masuk lewat `INSERT` berparameter.
- **Alasan keputusan:** Pertahanan hanya di pintu masuk (`INSERT` berparameter) menyimpan payload berbahaya secara utuh ke dalam kolom tabel sebagai data sah. Ketika fungsi laporan di kemudian hari membaca kolom tersebut dan merangkainya ke string `EXECUTE` tanpa `USING`, payload tersebut meledak menjadi perintah SQL (*second-order injection*). Oleh karena itu, setiap titik konsumsi data dinamis wajib memakai parameter (`USING $1`).

### Q18 · Batas waktu query
**Penanggung jawab:** Agi · **Berkas:** `q18_batas_waktu.sql`

- **Peran yang menjalankan:** `postgres` dan `app_laporan`
- **Perintah:**
```sql
ALTER ROLE app_laporan SET statement_timeout = '5s';
ALTER ROLE app_portal  SET statement_timeout = '5s';

SELECT rolname, rolconfig
FROM pg_roles
WHERE rolname IN ('app_laporan', 'app_portal')
ORDER BY rolname;

BEGIN;
  SET LOCAL ROLE app_laporan;
  SET LOCAL statement_timeout = '200ms';
  SELECT pg_sleep(2) AS simulasi_query_berat;
COMMIT;
```
- **Keluaran nyata:**
```text
ALTER ROLE
ALTER ROLE
   rolname   |       rolconfig        
-------------+------------------------
 app_laporan | {statement_timeout=5s}
 app_portal  | {statement_timeout=5s}

ERROR:  canceling statement due to statement timeout
ROLLBACK
```
- **Uji negatif (bila relevan):** Query lambat `pg_sleep(2)` otomatis diputus mesin basis data setelah `200ms` dengan pesan galat `ERROR: canceling statement due to statement timeout`.
- **Alasan keputusan:** Memasang `statement_timeout` di tingkat peran basis data membatasi konsumsi sumber daya CPU dan kunci (*lock*) apabila penyerang menyuntikkan fungsi penunda (`pg_sleep`) atau query berat (*Denial of Service*).

### Q19 · Hash vs enkripsi
**Penanggung jawab:** Azkha · **Berkas:** `q19_hash_vs_enkripsi.sql`

- **Peran yang menjalankan:** `postgres` (dalam transaksi `ROLLBACK`)
- **Perintah:**
```sql
SELECT id, username, kata_sandi AS sandi_awal
FROM lab11.akun ORDER BY id LIMIT 3;

BEGIN;
  UPDATE lab11.akun
  SET kata_sandi = crypt('rahasia123', gen_salt('bf', 8))
  WHERE id IN (1, 2);

  SELECT id, username,
         kata_sandi AS hash_tersimpan,
         (kata_sandi = crypt('rahasia123', kata_sandi)) AS verifikasi_sandi_benar,
         (kata_sandi = crypt('salah999', kata_sandi))   AS verifikasi_sandi_salah
  FROM lab11.akun WHERE id IN (1, 2) ORDER BY id;

  WITH uji_enkripsi AS (
    SELECT id, nama, pgp_sym_encrypt(nik, 'kunci-master-lab11') AS nik_terenkripsi
    FROM lab11.pelanggan WHERE id = 1
  )
  SELECT id, nama,
         encode(nik_terenkripsi, 'base64') AS ciphertext_base64,
         pgp_sym_decrypt(nik_terenkripsi, 'kunci-master-lab11') AS hasil_dekripsi
  FROM uji_enkripsi;
ROLLBACK;
```
- **Keluaran nyata:**
```text
 id |  username  |                        hash_tersimpan                        | verifikasi_sandi_benar | verifikasi_sandi_salah 
----+------------+--------------------------------------------------------------+------------------------+------------------------
  1 | admin_alfa | $2a$08$fZoY8wrPnt6Qh9hwKSdrF.tzZ0S11.PZU7M9S5kq4yG92sTfHIwFe | t                      | f
  2 | admin_beta | $2a$08$VTwl4X0RpXytmbfeGwFEcu.9UPrJlYR3w2Wr3mXaNuUHL6F58RjaC | t                      | f

 id |    nama     |                              ciphertext_base64                               |  hasil_dekripsi  
----+-------------+------------------------------------------------------------------------------+------------------
  1 | Pelanggan 1 | ww0EBwMCrTQy7XRh3kho0kEBQDM6qc65FehO28FXx1QG0xor+p1gtzKIICHNZfIIUuF1rrAqvohr+| 1271000000007919
    |             | yLp/dMjTvvsu64xOR5xgKSDuEPi0vlRL4Q==                                         | 
```
- **Uji negatif (bila relevan):** Pencocokan kata sandi dengan masukan salah (`salah999`) menghasilkan `verifikasi_sandi_salah = f`, sementara dua akun dengan kata sandi identik tetap menghasilkan string hash *bcrypt* berbeda berkat *salt* acak per baris.
- **Alasan keputusan:** Kata sandi tidak pernah perlu dipulihkan ke teks asal sehingga wajib memakai hash satu arah ber-*salt* (`crypt` + `gen_salt('bf')`), sedangkan atribut identitas seperti NIK masih dibutuhkan oleh aplikasi sehingga menggunakan enkripsi simetris dua arah (`pgp_sym_encrypt`/`pgp_sym_decrypt`).

### Q20 · Biaya kerja hash
**Penanggung jawab:** Azkha · **Berkas:** `q20_biaya_kerja_hash.sql`

- **Peran yang menjalankan:** `postgres`
- **Perintah:**
```sql
\timing on
SELECT encode(digest('rahasia123', 'sha256'), 'hex') AS hash_sha256_cepat;
SELECT crypt('rahasia123', gen_salt('bf', 4)) AS bcrypt_cost_4;
SELECT crypt('rahasia123', gen_salt('bf', 8)) AS bcrypt_cost_8;
SELECT crypt('rahasia123', gen_salt('bf', 12)) AS bcrypt_cost_12;
\timing off
```
- **Keluaran nyata:**
```text
hash_sha256_cepat : bee5688aea66a47460b19c76f8f199c6b9585eb726f8322b1429793863609ca2  | Time: 0.731 ms
bcrypt_cost_4     : $2a$04$2K0OU83032gGGh1J7N003uAQaYa1lXCQNPIKqyQVSr9AGOUt17qxW      | Time: 1.007 ms
bcrypt_cost_8     : $2a$08$.yXLbpvRphxjTJkQmd0QiOBzMgjf3yWdFKYW1Q70Y2sTPak0yB/F.      | Time: 12.241 ms
bcrypt_cost_12    : $2a$12$eZD/UQwPCFOT3NFOfFf5fOLrCgwGbnJ73s2.u6TW7WsxFPFrWgm/m      | Time: 177.335 ms
```
- **Uji negatif (bila relevan):** Hash kriptografi cepat seperti `SHA-256` selesai dalam `0.731 ms`, sehingga memungkinkan penyerang melakukan tebakan *brute-force* massal berkecepatan tinggi bila tabel akun bocor.
- **Alasan keputusan:** Fungsi hash adaptif *bcrypt* sengaja menambah iterasi eksponensial ($2^{\text{cost}}$) agar biaya komputasi penyerang melonjak tajam. Faktor biaya `cost = 12` (`177.335 ms`) memberi keseimbangan ideal: latensi di bawah 200 ms tetap nyaman untuk autentikasi pengguna sah, tetapi memperlambat serangan tebakan sandi ratusan kali lipat.

### Q21 · Enkripsi kolom
**Penanggung jawab:** Azkha · **Berkas:** `q21_enkripsi_kolom.sql`

- **Peran yang menjalankan:** `postgres` (dalam transaksi `ROLLBACK`)
- **Perintah:**
```sql
BEGIN;
  ALTER TABLE lab11.pelanggan ADD COLUMN nik_enc bytea, ADD COLUMN rekening_enc bytea;
  SET LOCAL app.enc_key = 'KunciRahasia-KMS-2026!';

  UPDATE lab11.pelanggan
  SET nik_enc      = pgp_sym_encrypt(nik, current_setting('app.enc_key')),
      rekening_enc = pgp_sym_encrypt(rekening, current_setting('app.enc_key'))
  WHERE id <= 3;

  SELECT id, nama,
         left(encode(nik_enc, 'hex'), 32) || '...' AS nik_ciphertext_hex,
         left(encode(rekening_enc, 'hex'), 32) || '...' AS rekening_ciphertext_hex
  FROM lab11.pelanggan WHERE id <= 3 ORDER BY id;

  SELECT id, nama,
         pgp_sym_decrypt(nik_enc, current_setting('app.enc_key'))      AS nik_terdekripsi,
         pgp_sym_decrypt(rekening_enc, current_setting('app.enc_key')) AS rekening_terdekripsi
  FROM lab11.pelanggan WHERE id <= 3 ORDER BY id;

  SELECT pgp_sym_decrypt(nik_enc, 'KunciSalah123') AS coba_kunci_salah
  FROM lab11.pelanggan WHERE id = 1;
ROLLBACK;
```
- **Keluaran nyata:**
```text
 id |    nama     |         nik_ciphertext_hex          |       rekening_ciphertext_hex       
----+-------------+-------------------------------------+-------------------------------------
  1 | Pelanggan 1 | c30d04070302a611a9889043b36978d2... | c30d040703029706d0b34115641378d2...
  2 | Pelanggan 2 | c30d040703025638911242f55f886ad2... | c30d04070302ec4c88412ef5700164d2...
  3 | Pelanggan 3 | c30d04070302ccf1f3e1265f6acf61d2... | c30d040703023ef76e37bc84dc4763d2...

 id |    nama     | nik_terdekripsi  | rekening_terdekripsi 
----+-------------+------------------+----------------------
  1 | Pelanggan 1 | 1271000000007919 | 0000104729
  2 | Pelanggan 2 | 1271000000015838 | 0000209458
  3 | Pelanggan 3 | 1271000000023757 | 0000314187

ERROR:  Wrong key or corrupt data
```
- **Uji negatif (bila relevan):** Percobaan dekripsi menggunakan kunci yang salah (`KunciSalah123`) langsung ditolak dengan galat `ERROR: Wrong key or corrupt data`.
- **Alasan keputusan:** Menyimpan *ciphertext* bertipe `bytea` di kolom tabel sementara kunci disuntikkan dari luar basis data (aplikasi/KMS via variabel sesi `app.enc_key`) melindungi kerahasiaan data apabila berkas penyimpanan atau salinan cadangan (`pg_dump`) jatuh ke pihak tidak berwenang.

### Q22 · Kunci bocor
**Penanggung jawab:** Azkha · **Berkas:** `q22_kunci_bocor.sql`

- **Peran yang menjalankan:** `postgres` (dalam transaksi `ROLLBACK`)
- **Perintah:**
```sql
BEGIN;
  ALTER TABLE lab11.pelanggan ADD COLUMN nik_enc bytea, ADD COLUMN versi_kunci smallint DEFAULT 1;
  UPDATE lab11.pelanggan
  SET nik_enc = pgp_sym_encrypt(nik, 'KunciLama-V1-2026'), versi_kunci = 1
  WHERE id <= 2;

  CREATE VIEW lab11.v_pelanggan_buruk AS
  SELECT id, nama, pgp_sym_decrypt(nik_enc, 'KunciLama-V1-2026') AS nik
  FROM lab11.pelanggan;

  SELECT viewname, definition AS definisi_view_membocorkan_kunci
  FROM pg_views WHERE schemaname = 'lab11' AND viewname = 'v_pelanggan_buruk';

  SET LOCAL app.kunci_lama = 'KunciLama-V1-2026';
  SET LOCAL app.kunci_baru = 'KunciBaru-V2-Rotasi!';

  UPDATE lab11.pelanggan
  SET nik_enc = pgp_sym_encrypt(
                  pgp_sym_decrypt(nik_enc, current_setting('app.kunci_lama')),
                  current_setting('app.kunci_baru')
                ),
      versi_kunci = 2
  WHERE versi_kunci = 1 AND id <= 2;

  SELECT id, nama, versi_kunci,
         pgp_sym_decrypt(nik_enc, current_setting('app.kunci_baru')) AS nik_dengan_kunci_v2
  FROM lab11.pelanggan WHERE id <= 2 ORDER BY id;

  SELECT pgp_sym_decrypt(nik_enc, current_setting('app.kunci_lama')) AS coba_kunci_bocor
  FROM lab11.pelanggan WHERE id = 1;
ROLLBACK;
```
- **Keluaran nyata:**
```text
     viewname      |                definisi_view_membocorkan_kunci                 
-------------------+----------------------------------------------------------------
 v_pelanggan_buruk |  SELECT id,                                                   +
                   |     nama,                                                     +
                   |     pgp_sym_decrypt(nik_enc, 'KunciLama-V1-2026'::text) AS nik+
                   |    FROM lab11.pelanggan;

 id |    nama     | versi_kunci | nik_dengan_kunci_v2 
----+-------------+-------------+---------------------
  1 | Pelanggan 1 |           2 | 1271000000007919
  2 | Pelanggan 2 |           2 | 1271000000015838

ERROR:  Wrong key or corrupt data
```
- **Uji negatif (bila relevan):** Setelah rotasi kunci ke `versi_kunci = 2`, pemakaian kunci lama yang bocor (`KunciLama-V1-2026`) ditolak dengan `ERROR: Wrong key or corrupt data`.
- **Alasan keputusan:** Menanam kunci di dalam definisi *view* atau tabel konfigurasi membuat kunci ikut terbaca lewat katalog sistem (`pg_views`) dan salinan `pg_dump`. Penyimpanan kunci wajib dipisah di pengelola kunci eksternal (KMS) disertai kolom `versi_kunci` agar rotasi kunci (*re-encryption*) dapat dilakukan tanpa henti layanan apabila kunci terindikasi bocor.

### Q23 · Penyamaran
**Penanggung jawab:** Azkha · **Berkas:** `q23_penyamaran.sql`

- **Peran yang menjalankan:** `postgres` dan `app_laporan` (dalam transaksi `ROLLBACK`)
- **Perintah:**
```sql
BEGIN;
  CREATE VIEW lab11.v_pelanggan_samaran AS
  SELECT id, tenant_id, nama,
         left(nik, 4) || repeat('*', 8) || right(nik, 4) AS nik_samaran,
         left(split_part(surel, '@', 1), 2) || '***@' || split_part(surel, '@', 2) AS surel_samaran,
         kota, saldo,
         repeat('*', greatest(length(rekening) - 4, 0)) || right(rekening, 4) AS rekening_samaran
  FROM lab11.pelanggan
  WHERE tenant_id = NULLIF(current_setting('app.tenant', true), '')::integer;

  REVOKE SELECT ON lab11.pelanggan FROM app_read;
  GRANT SELECT ON lab11.v_pelanggan_samaran TO app_read;

  SET LOCAL ROLE app_laporan;
  SET LOCAL app.tenant = '1';

  SELECT id, nama, nik_samaran, surel_samaran, kota, rekening_samaran
  FROM lab11.v_pelanggan_samaran ORDER BY id LIMIT 3;

  SELECT id, nama, nik, rekening FROM lab11.pelanggan LIMIT 1;
ROLLBACK;
```
- **Keluaran nyata:**
```text
 id |    nama     |   nik_samaran    |   surel_samaran   |      kota       | rekening_samaran 
----+-------------+------------------+-------------------+-----------------+------------------
  1 | Pelanggan 1 | 1271********7919 | pe***@contoh.test | Binjai          | ******4729
  2 | Pelanggan 2 | 1271********5838 | pe***@contoh.test | Pematangsiantar | ******9458
  3 | Pelanggan 3 | 1271********3757 | pe***@contoh.test | Rantauprapat    | ******4187

ERROR:  permission denied for table pelanggan
```
- **Uji negatif (bila relevan):** Percobaan peran `app_laporan` membaca langsung tabel dasar `lab11.pelanggan` ditolak dengan `ERROR: permission denied for table pelanggan`.
- **Alasan keputusan:** Penyamaran melalui *view* yang diiringi pencabutan `SELECT` pada tabel dasar memastikan peran pelaporan hanya menerima format tersamar yang dibutuhkan untuk analisis tanpa membuka atribut sensitif mentah, sambil tetap mempertahankan penyaring `tenant_id` di dalam definisi *view*.

### Q24 · Identifikasi ulang
**Penanggung jawab:** Azkha · **Berkas:** `q24_identifikasi_ulang.sql`

- **Peran yang menjalankan:** `postgres` (dalam transaksi `ROLLBACK`)
- **Perintah:**
```sql
WITH kelompok_semu AS (
  SELECT kota, lahir, count(*) AS jumlah_orang
  FROM lab11.pelanggan GROUP BY kota, lahir
)
SELECT count(*) AS total_kombinasi_unik_tunggal
FROM kelompok_semu WHERE jumlah_orang = 1;

BEGIN;
  CREATE TEMP TABLE sumber_eksternal (nama_publik text, kota text, tgl_lahir date) ON COMMIT DROP;
  INSERT INTO sumber_eksternal (nama_publik, kota, tgl_lahir)
  SELECT nama, kota, lahir FROM lab11.pelanggan WHERE id IN (10, 25, 50);

  WITH dataset_tanpa_pengenal_langsung AS (
    SELECT id, tenant_id, kota, lahir, saldo FROM lab11.pelanggan
  )
  SELECT e.nama_publik AS identitas_terungkap, d.id AS id_internal,
         d.kota, d.lahir, d.saldo AS saldo_sensitif_terbaca
  FROM dataset_tanpa_pengenal_langsung d
  JOIN sumber_eksternal e ON d.kota = e.kota AND d.lahir = e.tgl_lahir
  ORDER BY d.id;
ROLLBACK;
```
- **Keluaran nyata:**
```text
 total_kombinasi_unik_tunggal 
------------------------------
                         6000

 identitas_terungkap | id_internal |      kota       |   lahir    | saldo_sensitif_terbaca 
---------------------+-------------+-----------------+------------+------------------------
 Pelanggan 10        |          10 | Pematangsiantar | 1961-01-05 |             1079190.00
 Pelanggan 25        |          25 | Binjai          | 1962-07-14 |             1197975.00
 Pelanggan 50        |          50 | Pematangsiantar | 1965-01-24 |             1395950.00
 Pelanggan 10        |       18010 | Pematangsiantar | 1961-01-05 |            53621190.00
 Pelanggan 25        |       18025 | Binjai          | 1962-07-14 |            53739975.00
 Pelanggan 50        |       18050 | Pematangsiantar | 1965-01-24 |            53937950.00
```
- **Uji negatif (bila relevan):** Meski seluruh pengenal langsung (`nama`, `nik`, `surel`, `rekening`) dihapus, sebanyak `6.000` baris tetap unik secara tunggal hanya dari `(kota, lahir)`, dan tautan (*join*) dengan data eksternal langsung mengungkap catatan beserta saldo spesifik individu.
- **Alasan keputusan:** Penghapusan pengenal langsung saja belum menghasilkan anonimisasi sejati karena atribut demografis bertindak sebagai pengenal semu (*quasi-identifiers*). Untuk pelepasan data analitik eksternal, diperlukan generalisasi rentang (misalnya tahun/dekade lahir atau wilayah provinsi) serta penerapan prinsip *k-anonymity*.

### Q25 · Tabel dan trigger audit
**Penanggung jawab:** Syifa · **Berkas:** `q25_*.sql`

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
**Penanggung jawab:** Syifa · **Berkas:** `q26_*.sql`

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
**Penanggung jawab:** Syifa · **Berkas:** `q27_*.sql`

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
**Penanggung jawab:** Syifa · **Berkas:** `q28_*.sql`

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
**Penanggung jawab:** Syifa · **Berkas:** `q29_*.sql`

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
**Penanggung jawab:** Syifa · **Berkas:** `q30_*.md`

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

### Refleksi C (Agi)
Satu lapis yang menghapus sebab masalah, dan peran tiga lapis lain (bukti Q14 dan Q18):

**Satu lapis yang menghapus sebab masalah SQL injection adalah query berparameter (*prepared statement* / placeholder `%s` atau `$1`)** yang memisahkan saluran perintah SQL dari data masukan pengguna sejak di protokol basis data (dibuktikan pada Q15 di mana payload `zz' OR '1'='1' --` mengembalikan `0 baris (aman)`).

Sementara itu, **tiga lapis pertahanan lainnya berperan sebagai pengendali dan pembatas dampak (*defense-in-depth*)** apabila salah satu jalur kode terlewat diparameterkan:
1. **Prinsip hak minimum per tabel dan peran non-pemilik (`app_read` / `app_laporan`):** Mencegah serangan lintas tabel maupun pengubahan struktur skema. Terbukti pada Q14 ketika payload `UNION SELECT` mencoba membaca kredensial di `lab11.akun`, basis data menolaknya dengan `permission denied for table akun`.
2. **Row-Level Security (`ENABLE/FORCE RLS` dan kebijakan penyewa):** Membatasi ruang lingkup baris hanya pada penyewa aktif sehingga injeksi tidak dapat menyeberang ke data penyewa lain. Terbukti pada Q14 di mana injeksi `OR '1'='1'` yang semula membocorkan `30.000` baris lintas penyewa menyusut menjadi `10.000` baris milik penyewa 1 saja.
3. **Batas waktu eksekusi (`statement_timeout`):** Membatasi ketersediaan sumber daya agar injeksi query berat atau fungsi penunda tidak melumpuhkan server (*Denial of Service*). Terbukti pada Q18 di mana query `pg_sleep(2)` otomatis diputus oleh PostgreSQL dengan galat `canceling statement due to statement timeout`.

### Refleksi D (Azkha)
Dua ancaman yang tetap terbuka dan satu risiko operasional enkripsi kolom (bukti Q21–Q24):

Meskipun enkripsi kolom dan penyamaran (*masking*) telah diterapkan pada Q21–Q23, terdapat **dua ancaman keamanan yang tetap terbuka**:
1. **Kompromi pada lapisan aplikasi atau sesi aktif yang memegang kunci dekripsi (bukti Q21 & Q22):** Enkripsi tingkat kolom hanya melindungi data saat diam (*at rest*) di media penyimpanan dan berkas cadangan (`pg_dump`). Ketika aplikasi sah atau peran yang memiliki akses dekripsi menyuntikkan `app.enc_key` ke dalam sesi, data tetap didekripsi menjadi teks biasa di memori server; jika akun aplikasi tersebut dibajak atau mengalami celah injeksi, penyerang tetap memperoleh nilai asli.
2. **Serangan korelasi dan identifikasi ulang melalui pengenal semu (bukti Q23 & Q24):** Penyamaran kolom `nik`, `surel`, dan `rekening` pada *view* maupun penghapusan pengenal langsung tidak menyembunyikan distribusi pengenal semu seperti `kota` dan `lahir`. Pada Q24 terbukti sebanyak `6.000` baris tetap memiliki kombinasi `(kota, lahir)` yang unik secara tunggal sehingga tetap dapat ditautkan (*re-identification*) dengan sumber data eksternal untuk mengungkap informasi finansial (`saldo`).

**Satu risiko operasional utama enkripsi kolom** adalah **kehilangan permanen akses data apabila kunci hilang serta gangguan pengindeksan/pencarian dan rotasi kunci skala besar (bukti Q21 & Q22):** Karena *ciphertext* `pgp_sym_encrypt` menggunakan *salt* acak, nilai plaintext yang sama menghasilkan *ciphertext* berbeda sehingga indeks B-Tree standar tidak lagi dapat dipakai untuk pencarian kesetaraan maupun rentang secara langsung. Selain itu, jika pengelola kunci eksternal (KMS) kehilangan kunci aktif tanpa salinan pemulihan, seluruh kolom terenkripsi tidak dapat dipulihkan selamanya, sementara pergantian kunci (*key rotation* pada Q22) menuntut proses dekripsi dan enkripsi ulang seluruh baris aktif secara bertahap dengan pelacakan `versi_kunci`.

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

| Nama                       | Tanda tangan              | Tanggal          |
|----------------------------|---------------------------|------------------|
| Jelita Hati Sinurat        |                           |                  |
| M. Dzakwan Ismail Rangkuti |M. Dzakwan Ismail Rangkuti | 18 November 2026 |
| Agi Aginta Sembiring       |Agi Aginta Sembiring       | 18 November 2026 |
| M. Azkha Amorie            |M. Azkha Amorie            | 18 November 2026 |
| Syifa Nazira               |                           |                  |

## Penggunaan AI dan Verifikasi
| Nama                      -| Bagian yang dibantu AI | Cara memverifikasi (dijalankan ulang, dibandingkan dengan materi, dst.) |
|----------------------------|------------------------|-------------------------------------------------------------------------|
| Jelita Hati Sinurat        |                        |                                                                         |
| M. Dzakwan Ismail Rangkuti | Penyusunan skrip pengujian RLS Q6–Q11 dan perumusan analisis Refleksi B | Menjalankan langsung seluruh skrip q06–q11 di kontainer lab11-db jaringan tertutup, memverifikasi angka keluaran (0 vs 10.000 vs 30.000 baris), dan mencocokkan dengan materi segmen 03. | 
| Agi Aginta Sembiring       | Penyusunan skrip uji SQL injection Q12–Q18, perbaikan `rentan.py`, dan analisis Refleksi C | Menjalankan seluruh skrip dan payload pada kontainer `lab11-web` serta `lab11-db` di jaringan tertutup, dan memverifikasi keluaran nyata tiap percobaan. |
| M. Azkha Amorie            | Penyusunan skrip uji kriptografi, enkripsi kolom, penyamaran (masking), dan identifikasi ulang Q19–Q24 serta analisis Refleksi D | Menjalankan seluruh skrip pada kontainer `lab11-db` dalam transaksi `ROLLBACK`, menguji skenario kunci salah dan rotasi kunci bocor, serta memverifikasi keluaran nyata tiap percobaan. |
| Syifa Nazira               |                        |                                                                         |