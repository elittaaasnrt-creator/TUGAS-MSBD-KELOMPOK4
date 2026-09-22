# lab5_driver.py
# Diminta: memanggil procedure dengan COMMIT internal dari dalam blok transaksi aplikasi (Q4).
# Dipilih: psycopg.connect biasa (bukan pool) karena Q4 hanya perlu membuktikan satu galat spesifik, pool baru dipakai mulai Q14.
# Alternatif: menjalankan lewat psql -c; tidak dipilih karena soal eksplisit minta "dipanggil dari Python di dalam with psycopg.connect(...)".

import psycopg

DSN = "postgresql://msbd:msbd2026@localhost:5432/pagila"

with psycopg.connect(DSN) as conn:
    try:
        conn.execute(
            "CALL lab5.process_rental_bad_commit(%s::integer, %s::integer, %s::integer, %s::numeric)",
            (1, 1, 1, 4.99),
        )
    except psycopg.Error as exc:
        print("GALAT:", exc)