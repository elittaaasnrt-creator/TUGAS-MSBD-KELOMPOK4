-- 1. Tabel Anggota (KD-01)
CREATE TABLE anggota (
    id_anggota bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    no_id varchar(30) NOT NULL UNIQUE,
    nama varchar(100) NOT NULL,
    kategori varchar(30) NOT NULL,
    status varchar(20) NOT NULL DEFAULT 'aktif'
        CHECK (status IN ('aktif', 'ditangguhkan', 'keluar'))
);

-- 2. Tabel Alat / Katalog Alat (KD-02)
CREATE TABLE alat (
    id_alat bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nama_alat varchar(100) NOT NULL,
    kategori varchar(50) NOT NULL,
    deskripsi text,
    merk varchar(50)
);

-- 3. Tabel Unit Alat / Fisik Barang (KD-03)
CREATE TABLE unit_alat (
    id_unit bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_alat bigint NOT NULL REFERENCES alat(id_alat),
    no_inv varchar(50) NOT NULL UNIQUE,
    status varchar(20) NOT NULL DEFAULT 'tersedia'
        CHECK (status IN ('tersedia', 'dipinjam', 'perbaikan', 'rusak'))
);

-- 4. Tabel Peminjaman (KD-04 & KD-06)
CREATE TABLE peminjaman (
    id_pinjam bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_anggota bigint NOT NULL REFERENCES anggota(id_anggota),
    petugas_id varchar(50),
    tgl_pinjam date NOT NULL DEFAULT current_date,
    jatuh_tempo date NOT NULL,
    tgl_kembali date,
    status varchar(20) NOT NULL DEFAULT 'berjalan'
        CHECK (status IN ('berjalan', 'selesai', 'terlambat')),
    catatan text,
    CONSTRAINT ck_pinjam_tempo CHECK (jatuh_tempo >= tgl_pinjam)
);