# rentan.py - Perbaikan pemanggilan default menggunakan cari_aman (query berparameter).
import os, sys, psycopg2

def konek():
    c = psycopg2.connect(host="lab11-db", dbname="msbd",
                         user=os.environ.get("DB_USER", "postgres"),
                         password=os.environ.get("DB_PASS", "lab11"))
    cur = c.cursor()
    cur.execute("SELECT set_config('app.tenant', '1', false)")
    return c, cur

def cari_rentan(kata):
    c, cur = konek()
    sql = ("SELECT id, nama, kota FROM lab11.pelanggan "
           "WHERE tenant_id = 1 AND nama ILIKE '%" + kata + "%'")
    print("SQL:", sql)
    cur.execute(sql)
    print(len(cur.fetchall()), "baris")

def cari_aman(kata):
    c, cur = konek()
    cur.execute("SELECT id, nama, kota FROM lab11.pelanggan "
                "WHERE tenant_id = 1 AND nama ILIKE %s LIMIT 100", (f"%{kata}%",))
    print(len(cur.fetchall()), "baris (aman)")

if __name__ == "__main__":
    kata = sys.argv[1]
    (cari_rentan if len(sys.argv) > 2 and sys.argv[2] == "rentan" else cari_aman)(kata)