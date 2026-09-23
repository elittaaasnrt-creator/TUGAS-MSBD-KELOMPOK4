# q11_uji_injeksi.py
# Diminta: mencetak SQL hasil f-string dengan payload injeksi tanpa menjalankannya, lalu membuktikan versi berparameter aman dari payload yang sama.
# Dipilih: menampilkan string f-string sebagai teks saja (print), tidak pernah dieksekusi sebagai query, sesuai aturan sesi ini (payload injeksi tidak boleh dijalankan sebagai SQL yang dirangkai).
# Alternatif: langsung menjalankan f-string ke database untuk "membuktikan" bahayanya; tidak dipilih karena berisiko merusak data dan melanggar aturan latihan.

import psycopg

DSN = "postgresql://msbd:msbd2026@localhost:5432/pagila"

payload = "SMITH' OR '1'='1"

# --- versi TIDAK aman (hanya dicetak, TIDAK dijalankan) ---
sql_rentan = f"SELECT * FROM public.customer WHERE last_name = '{payload}'"
print("SQL hasil f-string (TIDAK dijalankan):")
print(sql_rentan)

# --- versi aman dengan parameter binding ---
print("\nHasil query berparameter (payload sama):")
with psycopg.connect(DSN) as conn:
    rows = conn.execute(
        "SELECT * FROM public.customer WHERE last_name = %s",
        (payload,),
    ).fetchall()
    print(rows)
    print(f"Jumlah baris: {len(rows)}")