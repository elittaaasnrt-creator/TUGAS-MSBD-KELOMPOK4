# Diminta: Implementasi driver PostgreSQL menggunakan psycopg 3 (Q4, Q10-Q15) mencakup parameter binding, identifier, penanganan transaksi, dan connection pool.
# Dipilih: Parameter binding (%s), sql.Identifier untuk nama kolom/tabel, serta ConnectionPool untuk manajemen koneksi.
# Alternatif: String interpolation (f-string); tidak dipilih karena rentan terhadap SQL Injection dan syntax error.

import os
import time
import psycopg
from psycopg import sql
from psycopg_pool import ConnectionPool

# Konfigurasi DSN (Ubah 'pagila' ke nama database kalian jika berbeda)
DSN = os.getenv("DSN", "postgresql://msbd:msbd2026@localhost:5432/pagila")

def run_q4():
    print("\n--- Q04: Memanggil Procedure dengan COMMIT Internal ---")
    try:
        with psycopg.connect(DSN) as conn:
            conn.execute(
                "CALL lab5.process_rental_bad_commit(%s::integer, %s::integer, %s::integer, %s::numeric)",
                (1, 1, 1, 4.99),
            )
    except psycopg.Error as exc:
        print("GALAT Q4 DITANGKAP:", exc)


def run_q10(conn):
    print("\n--- Q10: SELECT Berparameter ---")
    query = "SELECT customer_id, first_name, last_name FROM public.customer WHERE customer_id = %s;"
    customer_id = 1
    with conn.cursor() as cur:
        cur.execute(query, (customer_id,))
        result = cur.fetchone()
        print(f"Potongan Kode: cur.execute('{query}', ({customer_id},))")
        print(f"Hasil Query: {result}")


def run_q11(conn):
    print("\n--- Q11: Uji Injeksi SQL ---")
    payload = "SMITH' OR '1'='1"
    
    # 1. Menampilkan f-string (TIDAK DIJALANKAN ke database demi keamanan)
    f_string_sql = f"SELECT * FROM public.customer WHERE last_name = '{payload}';"
    print(f"[DANGER] Tampilan SQL jika pakai f-string (TIDAK dijalankan):")
    print(f"         {f_string_sql}")
    
    # 2. Menjalankan versi berparameter aman
    query = "SELECT customer_id, first_name, last_name FROM public.customer WHERE last_name = %s;"
    with conn.cursor() as cur:
        cur.execute(query, (payload,))
        results = cur.fetchall()
        print(f"[SAFE] Hasil versi berparameter dengan payload ('{payload}'):")
        print(f"       Jumlah baris ditemukan: {len(results)} (Hasil kosong terbukti aman)")


def run_q12(conn):
    print("\n--- Q12: Identifier dan Allow-List ---")
    user_input_col = "first_name"  # Kolom yang ingin di-sort
    allow_list = ["customer_id", "first_name", "last_name", "email"]
    
    # Percobaan Gagal: Mengirim nama kolom sebagai parameter nilai (%s)
    print("1. Percobaan gagal jika nama kolom dikirim sebagai %s:")
    try:
        conn.execute("SELECT customer_id, first_name FROM public.customer ORDER BY %s LIMIT 3;", (user_input_col,))
    except Exception as e:
        print(f"   Pesan Galat Ditangkap: {e}")

    # Perbaikan: Menggunakan allow-list dan sql.Identifier
    print("2. Perbaikan aman menggunakan allow-list & sql.Identifier:")
    if user_input_col in allow_list:
        query = sql.SQL("SELECT customer_id, first_name FROM public.customer ORDER BY {} LIMIT 3;").format(
            sql.Identifier(user_input_col)
        )
        with conn.cursor() as cur:
            cur.execute(query)
            results = cur.fetchall()
            print(f"   SQL Dihasilkan: {query.as_string(conn)}")
            print(f"   Hasil: {results}")


def run_q13():
    print("\n--- Q13: Rollback dari Sisi Aplikasi ---")
    with psycopg.connect(DSN) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT count(*) FROM lab5.rental_tx;")
            count_before = cur.fetchone()[0]
    print(f"Jumlah baris rental_tx SEBELUM exception: {count_before}")

    try:
        with psycopg.connect(DSN) as conn:
            print("Memanggil lab5.process_rental(1, 1, 1, 4.99)...")
            conn.execute("CALL lab5.process_rental(%s::integer, %s::integer, %s::integer, %s::numeric, '{}'::jsonb, %s);", (1, 1, 1, 4.99, None))
            print("Melempar RuntimeError sebelum blok 'with' selesai...")
            raise RuntimeError("gagal di tengah alur")
    except RuntimeError as e:
        print(f"Ditangkap Exception Python: {e}")

    with psycopg.connect(DSN) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT count(*) FROM lab5.rental_tx;")
            count_after = cur.fetchone()[0]
    print(f"Jumlah baris rental_tx SESUDAH exception: {count_after}")


def run_q14():
    print("\n--- Q14: ConnectionPool ---")
    with ConnectionPool(conninfo=DSN, min_size=2, max_size=2) as pool:
        print("Menjalankan 5 permintaan berurutan menggunakan pool...")
        for i in range(1, 6):
            with pool.connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT %s AS request_id, pg_backend_pid();", (i,))
                    res = cur.fetchone()
                    print(f"  Permintaan #{res[0]} ditangani oleh Backend PID: {res[1]}")
        
        stats = pool.get_stats()
        print(f"Statistik Pool (pool.get_stats()): {stats}")


def run_q15():
    print("\n--- Q15: Idle in Transaction ---")
    print("Membuka transaksi dan mendiamkan selama 30 detik...")
    print("Jalankan perintah ini di psql lain:")
    print("SELECT pid, state, xact_start, query FROM pg_stat_activity WHERE state LIKE 'idle in%';\n")
    
    with psycopg.connect(DSN) as conn:
        conn.execute("SELECT 1;")
        time.sleep(30)


if __name__ == "__main__":
    print("=== EXEKUSI DRIVER LAB 5 ===")
    
    # Jalankan Q4 (Soal Jelita)
    run_q4()
    
    # Jalankan Q10-Q12
    with psycopg.connect(DSN) as conn:
        run_q10(conn)
        run_q11(conn)
        run_q12(conn)
    
    # Jalankan Q13-Q15 (Soal Mael)
    run_q13()
    run_q14()
    run_q15()