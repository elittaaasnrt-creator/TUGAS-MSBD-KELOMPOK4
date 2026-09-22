# Latihan Pertemuan 5 — Dari Procedure sampai Endpoint

## Prasyarat

- Docker & Docker Compose (untuk container `msbd-pg`, PostgreSQL 17)
- Python 3.x dengan `venv`
- Package Python: `psycopg[binary,pool]==3.2.*`, `sqlalchemy==2.0.*`, `fastapi==0.115.*`, `uvicorn==0.32.*`, `pydantic==2.*`

## Variabel DSN

DSN = postgresql://msbd:msbd2026@localhost:5432/pagila

Catatan: nama database yang dipakai adalah **`pagila`** (berisi data DVD rental — tabel `customer`, `inventory`, `staff`, dll), bukan `latihan` yang tercantum default di `docker-compose.yml`.

## Cara Setup Skema lab5

1. Jalankan container:

```bash
   docker compose up -d
   docker compose ps
```

2. Buat virtual environment dan install dependencies:

```bash
   python -m venv .venv
   .venv\Scripts\Activate.ps1        # Windows PowerShell
   # source .venv/bin/activate       # macOS/Linux
   pip install "psycopg[binary,pool]==3.2.*" "sqlalchemy==2.0.*" "fastapi==0.115.*" "uvicorn==0.32.*" "pydantic==2.*"
```

3. Jalankan skema `lab5` ke database `pagila`:

```bash
   Get-Content latihan\p05\q00_setup.sql | docker exec -i msbd-pg psql -U msbd -d pagila
```

4. Verifikasi:

```bash
   python -c "import psycopg, sqlalchemy, fastapi; print(psycopg.__version__, sqlalchemy.__version__, fastapi.__version__)"
   docker exec -i msbd-pg psql -U msbd -d pagila -c "SELECT version();" -c "SELECT count(*) AS jumlah_customer FROM public.customer;"
```

5. Soal Q1–Q9 (PL/pgSQL & tipe data), jalankan tiap file `.sql` dengan pola yang sama:

```bash
   Get-Content latihan\p05\qNN_nama_file.sql | docker exec -i msbd-pg psql -U msbd -d pagila
```

## Cara Menjalankan Tiga Program Python

**1. `lab5_driver.py`** (Q10–Q15 — psycopg: binding, transaksi, pool)

```bash
python latihan\p05\lab5_driver.py
```

**2. `lab5_orm.py`** (Q16–Q20 — SQLAlchemy ORM & N+1, `echo=True` aktif)

```bash
python latihan\p05\lab5_orm.py
```

**3. `lab5_api.py`** (Q21–Q24 — endpoint FastAPI)

```bash
uvicorn latihan.p05.lab5_api:app --reload
```

Endpoint aktif di `http://localhost:8000`, dokumentasi interaktif di `http://localhost:8000/docs`.

## Tiga curl untuk Q22–Q24

**Q22 — POST /rentals (nilai sah, harus 201)**

```bash
curl -s -X POST localhost:8000/rentals -H 'content-type: application/json' \
  -d '{"customer_id":1,"inventory_id":1,"staff_id":1,"amount":4.99}'
```

**Q23 — amount negatif (harus 422, bukan 500)**

```bash
curl -s -i -X POST localhost:8000/rentals -H 'content-type: application/json' \
  -d '{"customer_id":1,"inventory_id":1,"staff_id":1,"amount":-4.99}'
```

**Q24 — inventory_id tidak ada (harus 409)**

```bash
curl -s -i -X POST localhost:8000/rentals -H 'content-type: application/json' \
  -d '{"customer_id":1,"inventory_id":999999,"staff_id":1,"amount":4.99}'
```
