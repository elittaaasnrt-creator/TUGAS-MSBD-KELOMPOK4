# Diminta: Membangun endpoint HTTP FastAPI untuk memproses rental dan menangani error secara aman.
# Dipilih: Menggunakan psycopg_pool ConnectionPool dengan generator ContextManager (yield) serta FastAPI Exception Handling.
# Alternatif: Membuat koneksi baru per request; tidak dipilih karena berisiko memenuhi connection limit basis data.

from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel, PositiveFloat
from psycopg_pool import ConnectionPool
from psycopg.errors import ForeignKeyViolation, CheckViolation

DSN = "postgresql://msbd:msbd2026@localhost:5432/pagila"

# Q21: Connection Pool Lifecycle
pool = ConnectionPool(conninfo=DSN, open=False)

@asynccontextmanager
async def lifespan(app: FastAPI):
    pool.open()
    yield
    pool.close()

app = FastAPI(lifespan=lifespan)

# Q21: Dependency koneksi bergaya with yield
def get_conn():
    with pool.connection() as conn:
        yield conn

class RentalRequest(BaseModel):
    customer_id: int
    inventory_id: int
    staff_id: int
    # Q23: Validasi nilai amount positif di Pydantic (menghasilkan HTTP 422)
    amount: PositiveFloat

# Q22 - Q24: Endpoint POST /rentals
@app.post("/rentals", status_code=status.HTTP_201_CREATED)
def create_rental(payload: RentalRequest):
    try:
        with pool.connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "CALL lab5.process_rental(%s, %s, %s, %s, %s)",
                    (payload.customer_id, payload.inventory_id, payload.staff_id, payload.amount, None)
                )
                res = cur.fetchone()
                rental_id = res[0] if res else None
                conn.commit()
                return {"rental_id": rental_id, "message": "Rental berhasil diproses"}
    except ForeignKeyViolation:
        # Q24: Inventory / Customer / Staff tidak ditemukan di basis data
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Referensi data tidak ditemukan (Foreign Key Violation)."
        )
    except CheckViolation:
        # Q23: Jika ditolak domain basis data
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Nilai amount melanggar constraint basis data."
        )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Terjadi kesalahan internal pada server."
        )
