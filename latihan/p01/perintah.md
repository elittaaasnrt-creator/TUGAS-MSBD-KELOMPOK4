# Perintah — Latihan Pertemuan 1 (MSBD)

Dikerjakan oleh: Jelita Hati Sinurat (Project Manager)

## Langkah 1 — Docker

```
docker --version
docker compose version
docker run --rm hello-world
```
Tiga perintah ini dipakai buat mastiin Docker dan Docker Compose udah kepasang dan jalan normal di laptop. `docker run --rm hello-world` nyoba narik image kecil dari Docker Hub terus langsung dijalanin sebagai container, kalau muncul pesan "Hello from Docker!" berarti instalasi Docker-nya sukses.

## Langkah 2 — Docker Compose

```
mkdir dump
docker compose up -d
docker compose ps
docker compose logs postgres
```
`docker compose up -d` menjalankan tiga service sekaligus (postgres, mongo, redis) sesuai isi `docker-compose.yml`, mode `-d` supaya jalan di background. `docker compose ps` buat ngecek status tiap container udah `Up`/`healthy` apa belum. `docker compose logs postgres` buat lihat log startup PostgreSQL-nya.

## Langkah 3 — psql & DBeaver

```
docker compose exec postgres psql -U msbd -d latihan
```
Perintah ini masuk ke dalam container postgres terus buka `psql` (command line client-nya PostgreSQL), connect ke database `latihan` pakai user `msbd`.

Di dalam psql:
```sql
SELECT version();
\l
\dt
\dn
\du
SHOW data_directory;
SHOW shared_buffers;
\timing on
\q
```
- `SELECT version();` nunjukin versi PostgreSQL yang jalan.
- `\l` nampilin semua database yang ada.
- `\dt` nampilin tabel di database aktif (masih kosong karena Pagila belum di-restore).
- `\dn` nampilin schema.
- `\du` nampilin daftar role/user.
- `SHOW data_directory;` dan `SHOW shared_buffers;` nunjukin lokasi penyimpanan data fisik dan seberapa besar memori yang dialokasikan buat cache.
- `\timing on` ngaktifin tampilan waktu eksekusi tiap query.
- `\q` keluar dari psql.

Selain psql, database yang sama juga dicoba diakses lewat DBeaver (host `localhost`, port `5432`, database `latihan`, user `msbd`) buat lihat skema `public` dan buka ER Diagram.

## Langkah 4 — Restore Pagila

```
docker compose exec postgres createdb -U msbd pagila
docker compose exec postgres pg_restore -U msbd -d pagila --no-owner /dump/pagila.dump
docker compose exec postgres psql -U msbd -d pagila -c "\dt"
```
`createdb` bikin database kosong baru bernama `pagila`. `pg_restore` mengembalikan isi dump (`pagila.dump`) ke database itu — flag `--no-owner` supaya kepemilikan tabel ngikut user `msbd`, bukan user asal dump dibuat. Perintah terakhir buat verifikasi jumlah dan nama tabel yang berhasil di-restore (hasilnya 21 tabel).

Query verifikasi V1–V4 dijalankan langsung di dalam psql setelah connect ke database `pagila` — isi lengkap query ada di `verifikasi.sql`.

## Langkah 5 — Git & GitHub

```
git config --global user.name
git config --global user.email
git init
git add .
git commit -m "chore: menyiapkan lingkungan MSBD"
git branch -M main
git remote add origin https://github.com/elittaaasnrt-creator/TUGAS-MSBD-KELOMPOK4.git
git pull origin main --allow-unrelated-histories
git push origin main
```
`git init` bikin repository Git baru di folder lokal. `git add .` + `git commit` nyimpen snapshot pertama (docker-compose.yml dan .gitignore). `git remote add origin` nyambungin folder lokal ke repo GitHub tim. `git pull ... --allow-unrelated-histories` dipakai karena repo GitHub udah punya `README.md` duluan sementara folder lokal punya history commit sendiri, jadi perlu digabung manual. `git push origin main` ngirim semua commit ke GitHub.
