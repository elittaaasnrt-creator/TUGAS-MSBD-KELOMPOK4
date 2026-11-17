# Latihan P11 · Menutup Pintu yang Terbuka

Kelompok: Jelita, Mael, Azkha, Syifa, Agi · Cabang: `latihan/p11-keamanan`

> **Etika:** semua percobaan hanya sah di kontainer `lab11` milik sendiri pada jaringan tertutup (`Internal: true`). Payload hanya `SELECT`.

## Prasyarat
- Docker dan Docker Compose
- Git, akun Git masing-masing anggota
- Berkas dari modul praktikum: `docker-compose.lab11.yml`, `sql/lab11_setup.sql`, `app/`
- PostgreSQL 17 (di kontainer `lab11-db`), ekstensi `pgcrypto`

## Menyalakan dua kontainer
```bash
cd ~/msbd-2026/lab11
docker compose -f docker-compose.lab11.yml up -d
docker network inspect lab11_labnet --format '{{.Internal}}'   # harus true
```

## Memuat skema lab11
```bash
docker cp sql/lab11_setup.sql lab11-db:/sql/lab11_setup.sql
docker exec -i lab11-db psql -U postgres -d msbd -f /sql/lab11_setup.sql
```
Verifikasi: `3 | 30000 | 4 | 120000`, dan tiap penyewa 10000 pelanggan.

## Urutan menjalankan Q1–Q30
| Urutan | Berkas | Catatan ketergantungan |
|---|--------|---|
| 1 | `q00_setup.sql` | Wajib pertama |
| 2 | `q01`–`q05` | Peran dan hak |
| 3 | `q06`–`q08` | Kebijakan (Q7) sebelum uji (Q8) |
| 4 | `q09`–`q11` | Q9 memberi `pg_read_all_data` ke `app_analitik` |
| 5 | `q12`–`q18` | Jalankan di kontainer `lab11-web`; Q14 butuh RLS aktif |
| 6 | `q19`–`q22` | Q21 menambah kolom `rekening_enc` |
| 7 | `q23`–`q24` | Q23 mencabut `pg_read_all_data` (setelah Q9) |
| 8 | `q25`–`q29` | Q25 sebelum Q26 dan Q29 |
| 9 | `q30_peta_uu_pdp.md`, `laporan.md` | Terakhir |

Sebelum mengumpulkan, jalankan ulang semuanya berurutan dalam satu sesi bersih.

## Pembagian
| Anggota                    | Bagian                                                 |
|----------------------------|--------------------------------------------------------|
| Jelita Hati Sinurat        | Setup, Q1–Q5, README, integrasi laporan, merge request |
| M. Dzakwan Ismail Rangkuti | Q6–Q11                                                 |
| Agi Aginta Sembiring       | Q12–Q18, `rentan.py`                                   |
| M. Azkha Amorie            | Q19–Q24                                                |
| Syifa Nazira               | Q25–Q30                                                |

## Mengumpulkan
```bash
git add latihan/p11
git commit -m "Selesaikan latihan keamanan basis data pertemuan 11"
git push -u origin latihan/p11-keamanan
```
Lalu buka merge request dan tempel tautannya di `laporan.md`.