# Latihan Pertemuan 2 — Dari Kebutuhan ke Skema Berversi

**Kelompok:** TUGAS-MSBD-KELOMPOK 4
**Domain:** Peminjaman Alat Laboratorium

**Anggota:**

- Jelita Hati Sinurat - 251402141 (elittaaasnrt-creator)
- M. Ismail Dzakwan Rangkuti - 251402014 (dzakwanrangkuti)
- Agi Aginta Sembiring - 251402059 (agisembiring263-pixel)
- M. Azkha Amorie - 251402092 (azkhaamorie)
- Syifa Nazira - 251402126 (ziraa94)

---

## Cara Menjalankan Docker Compose

```bash
docker compose up -d
docker compose ps
```

## Cara Menjalankan Migration

```bash
docker compose run --rm flyway migrate
docker compose run --rm flyway info
```

## Cara Menjalankan Seed Data

```bash
docker compose exec -T postgres \
psql -U postgres -d proyek_dev \
< latihan/p02/seeds/01_peran.sql
```

# Jalankan perintah di atas 2x — jumlah baris di tabel peran

# harus tetap sama (tidak duplikat)
