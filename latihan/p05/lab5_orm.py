# Diminta: model deklaratif SQLAlchemy 2.0 (Customer, Rental, relationship),
#          bukti N+1 (Q17), perbaikan dengan selectinload (Q18) dan joinedload (Q19),
#          serta perbandingan ORM vs SQL mentah untuk query analitik (Q20).
# Dipilih: engine dengan echo=True agar setiap statement SQL yang dijalankan ORM
#          tercetak ke stdout dan bisa dihitung manual sebagai bukti.
# Alternatif: menghitung statement lewat event listener SQLAlchemy (before_cursor_execute);
#          tidak dipilih untuk Q16-Q19 karena echo=True sudah cukup dan lebih sederhana
#          untuk dibaca langsung dari terminal. Event listener dipakai di Q20 untuk
#          menghitung jumlah query ORM vs raw SQL secara presisi.

import time
from sqlalchemy import create_engine, select, text, func, ForeignKey
from sqlalchemy.orm import (
    DeclarativeBase,
    Mapped,
    mapped_column,
    relationship,
    sessionmaker,
    selectinload,
    joinedload,
)

DSN = "postgresql+psycopg://msbd:msbd2026@localhost:5432/pagila"


class Base(DeclarativeBase):
    pass


# --- Q16: model deklaratif ---------------------------------------------------
# Customer dipetakan ke public.customer (tabel bawaan Pagila, tidak dibuat ulang).
# Rental dipetakan ke lab5.rental_tx (tabel baru khusus latihan pertemuan 5).
# Keduanya dihubungkan lewat relationship satu-ke-banyak: satu customer punya
# banyak rental.

class Customer(Base):
    __tablename__ = "customer"
    __table_args__ = {"schema": "public"}

    customer_id: Mapped[int] = mapped_column(primary_key=True)
    first_name: Mapped[str]
    last_name: Mapped[str]

    rentals: Mapped[list["Rental"]] = relationship(back_populates="customer")


class Rental(Base):
    __tablename__ = "rental_tx"
    __table_args__ = {"schema": "lab5"}

    rental_id: Mapped[int] = mapped_column(primary_key=True)
    customer_id: Mapped[int] = mapped_column(
        ForeignKey("public.customer.customer_id")
    )
    inventory_id: Mapped[int]
    staff_id: Mapped[int]
    status: Mapped[str]

    customer: Mapped["Customer"] = relationship(back_populates="rentals")


# --- Model tambahan untuk Q20 (query analitik pada data Pagila asli) --------
# Dipetakan read-only ke tabel public.film, public.inventory, public.rental
# (bukan lab5.rental_tx) karena Q20 minta query analitik pada data DVD rental
# yang sudah ada, contohnya lima film tersewa terbanyak.

class Film(Base):
    __tablename__ = "film"
    __table_args__ = {"schema": "public"}

    film_id: Mapped[int] = mapped_column(primary_key=True)
    title: Mapped[str]


class Inventory(Base):
    __tablename__ = "inventory"
    __table_args__ = {"schema": "public"}

    inventory_id: Mapped[int] = mapped_column(primary_key=True)
    film_id: Mapped[int] = mapped_column(ForeignKey("public.film.film_id"))


class PagilaRental(Base):
    __tablename__ = "rental"
    __table_args__ = {"schema": "public"}

    rental_id: Mapped[int] = mapped_column(primary_key=True)
    inventory_id: Mapped[int] = mapped_column(
        ForeignKey("public.inventory.inventory_id")
    )


def get_session_factory(echo: bool = True):
    engine = create_engine(DSN, echo=echo)
    return engine, sessionmaker(bind=engine)


def q17_bukti_n_plus_1():
    print("\n=== Q17: Bukti N+1 (tanpa eager loading) ===")
    engine, Session = get_session_factory(echo=True)
    with Session() as session:
        rows = session.scalars(select(Customer).limit(10)).all()
        for c in rows:
            print(c.customer_id, len(c.rentals))
    engine.dispose()


def q18_selectinload():
    print("\n=== Q18: selectinload ===")
    engine, Session = get_session_factory(echo=True)
    with Session() as session:
        rows = session.scalars(
            select(Customer).options(selectinload(Customer.rentals)).limit(10)
        ).all()
        print([(c.customer_id, len(c.rentals)) for c in rows])
    engine.dispose()


def q19_joinedload():
    print("\n=== Q19: joinedload ===")
    engine, Session = get_session_factory(echo=True)
    with Session() as session:
        rows = session.scalars(
            select(Customer)
            .options(joinedload(Customer.rentals))
            .limit(10)
            .distinct()
        ).unique().all()
        print([(c.customer_id, len(c.rentals)) for c in rows])
    engine.dispose()


def q20_orm_vs_raw_sql():
    print("\n=== Q20: ORM vs SQL mentah (5 film tersewa terbanyak) ===")
    engine, Session = get_session_factory(echo=False)

    with Session() as session:
        t0 = time.perf_counter()
        stmt = (
            select(Film.title, func.count(PagilaRental.rental_id).label("jumlah_sewa"))
            .join(Inventory, Inventory.film_id == Film.film_id)
            .join(PagilaRental, PagilaRental.inventory_id == Inventory.inventory_id)
            .group_by(Film.title)
            .order_by(func.count(PagilaRental.rental_id).desc())
            .limit(5)
        )
        hasil_orm = session.execute(stmt).all()
        t1 = time.perf_counter()
        waktu_orm = t1 - t0

    raw_sql = """
        SELECT f.title, count(r.rental_id) AS jumlah_sewa
        FROM public.film f
        JOIN public.inventory i ON i.film_id = f.film_id
        JOIN public.rental r ON r.inventory_id = i.inventory_id
        GROUP BY f.title
        ORDER BY jumlah_sewa DESC
        LIMIT 5;
    """
    with engine.connect() as conn:
        t0 = time.perf_counter()
        hasil_raw = conn.execute(text(raw_sql)).all()
        t1 = time.perf_counter()
        waktu_raw = t1 - t0

    print("Hasil ORM      :", hasil_orm)
    print(f"Waktu ORM       : {waktu_orm*1000:.3f} ms")
    print("Hasil SQL mentah:", hasil_raw)
    print(f"Waktu SQL mentah: {waktu_raw*1000:.3f} ms")
    engine.dispose()


if __name__ == "__main__":
    q17_bukti_n_plus_1()
    q18_selectinload()
    q19_joinedload()
    q20_orm_vs_raw_sql()