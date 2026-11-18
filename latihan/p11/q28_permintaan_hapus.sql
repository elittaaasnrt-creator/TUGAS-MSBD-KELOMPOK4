-- Diminta: buat tabel permintaan_hapus menggunakan tenggat timestamptz NOT NULL
--          DEFAULT now() + interval '72 hours' (bukan kolom GENERATED).
-- Dipilih: definisi kolom tenggat dengan klausa DEFAULT sesuai batas waktu pemenuhan
--          hak penghapusan data pribadi (3 x 24 jam).
-- Alternatif: GENERATED ALWAYS AS (diterima_pada + interval '72 hours') STORED;
--             tidak dipilih karena ditolak PostgreSQL 17 dengan galat
--             "generation expression is not immutable" akibat aritmetika timestamptz.

CREATE TABLE IF NOT EXISTS lab11.permintaan_hapus (
    id serial PRIMARY KEY,
    pelanggan_id int NOT NULL,
    alasan text NOT NULL,
    diterima_pada timestamptz NOT NULL DEFAULT now(),
    tenggat timestamptz NOT NULL DEFAULT now() + interval '72 hours',
    status text NOT NULL DEFAULT 'DIPROSES'
);

-- HASIL:
-- CREATE TABLE
-- Penjelasan: penambahan interval terhadap timestamptz bergantung pada pengaturan zona waktu
-- sesi sehingga bersifat volatile/stable (bukan immutable). Penggunaan DEFAULT berhasil
-- menghitung tenggat 72 jam sejak baris permintaan dibuat tanpa melanggar aturan PostgreSQL 17.