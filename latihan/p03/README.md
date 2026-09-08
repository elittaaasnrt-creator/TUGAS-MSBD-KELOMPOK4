# Latihan Pertemuan 3 - SQL Lanjutan I

Latihan kelompok menulis dua puluh query bertingkat (subquery, CTE & recursive CTE, window function, agregasi lanjutan, JSONB) dan satu laporan analitik terpadu (R1) di atas basis data Pagila.

## Prasyarat

- Docker aktif
- PostgreSQL 17
- Basis data Pagila sudah terisi

**Catatan environment kelompok kami:** `docker-compose.yml` kami pakai nama service `postgres` (bukan `db` seperti di modul) dan user `msbd` (bukan `postgres`). Kami juga pakai Windows PowerShell, yang tidak mendukung `<` redirect, jadi semua file `.sql` dijalankan lewat `Get-Content ... | docker compose exec -T ...` alih-alih `-f /dev/stdin < file.sql`.

## Menjalankan Setup

```powershell
Get-Content latihan\p03\q00_setup.sql -Raw | docker compose exec -T postgres psql -U msbd -d pagila -f -
```

## Menjalankan Jawaban

```powershell
Get-Content latihan\p03\q01_tarif_di_atas_rata.sql -Raw | docker compose exec -T postgres psql -U msbd -d pagila -f -
```

Ganti nama file sesuai nomor soal yang ingin dijalankan (`q02_...sql`, dst, sampai `r1_laporan_bulanan.sql`). Urutan pengerjaan **tidak harus berurutan** per anggota — bebas mulai dari soal mana saja, asal `q00_setup.sql` sudah dijalankan lebih dulu (karena Q6-Q9 butuh tabel `pegawai` dan Q19-Q20 butuh tabel `notifikasi`).

## Catatan Q9

Q9 mengubah relasi atasan pada tabel `pegawai` sementara untuk menguji ketahanan recursive CTE terhadap siklus. Setelah pengujian selesai, data **wajib** dipulihkan dengan:

```sql
UPDATE pegawai SET atasan_id = NULL WHERE pegawai_id = 1;
```

## Pembagian Soal

- Jelita Hati Sinurat - q00_setup.sql, Q1-Q5 (subquery)
- M. Ismail Dzakwan Rangkuti - Q6-Q8 (CTE)
- Agi Aginta Sembiring - Q9-Q12 (recursive CTE, window function awal)
- M. Azkha Amorie - Q13-Q16 (window function lanjutan, ROLLUP)
- Syifa Nazira - Q17-Q20 (agregasi FILTER, operasi himpunan, JSONB)
- R1, laporan.md, README.md dikerjakan bersama

## Anggota

- Jelita Hati Sinurat - 251402141
- M. Ismail Dzakwan Rangkuti - 251402014
- Agi Aginta Sembiring - 251402059
- M. Azkha Amorie - 251402092
- Syifa Nazira - 251402126
