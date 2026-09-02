## Lingkup

| Termasuk | Tidak termasuk |
|---|---|
| Katalog alat dan unit fisik alat lab | Pengadaan alat |
| Peminjaman dan pengembalian | Pembayaran denda |
| Perhitungan denda keterlambatan | Data induk mahasiswa |
| Riwayat perbaikan alat | Jadwal praktikum

---

### KD-01 Pendataan anggota lab

- Deskripsi : mencatat data mahasiswa dan dosen yang berhak meminjam alat
- Data      : id_anggota, no_id, nama, kategori, status
- Aturan    : hanya anggota berstatus aktif yang boleh mengajukan peminjaman
- Volume    : ±500 anggota
- Sumber    : pendaftaran anggota lab
- Prioritas : wajib

### KD-02 Katalog jenis alat

- Deskripsi : mengelola daftar kategori dan spesifikasi jenis alat laboratorium
- Data      : id_alat, nama_alat, kategori, deskripsi, merk
- Aturan    : satu jenis alat dapat memiliki banyak unit fisik barang
- Volume    : ±100 jenis alat
- Sumber    : inventarisasi lab
- Prioritas : wajib

### KD-03 Unit fisik alat

- Deskripsi : mencatat kondisi dan ketersediaan dari tiap unit barang secara spesifik
- Data      : id_unit, id_alat, no_inv, status
- Aturan    : unit bernilai status dipinjam atau perbaikan tidak dapat dipinjamkan
- Volume    : ±300 unit
- Sumber    : hasil inventarisasi unit
- Prioritas : wajib

### KD-04 Transaksi peminjaman

- Deskripsi : mencatat proses peminjaman alat lab oleh anggota
- Data      : id_pinjam, id_anggota, tgl_pinjam, jatuh_tempo, status
- Aturan    : maksimal 3 unit alat per anggota dalam satu waktu; jatuh tempo tidak boleh kurang dari tgl_pinjam
- Volume    : ±30 transaksi/hari
- Sumber    : formulir peminjaman
- Prioritas : wajib

### KD-05 Detail item peminjaman

- Deskripsi : mencatat daftar unit alat fisik yang masuk dalam satu transaksi peminjaman
- Data      : id_detail, id_pinjam, id_unit, kondisi_awal
- Aturan    : status unit otomatis berubah menjadi dipinjam saat transaksi dibuat
- Volume    : ±60 item/hari
- Sumber    : formulir peminjaman
- Prioritas : wajib

### KD-06 Pengembalian alat

- Deskripsi : petugas mencatat pengembalian unit alat oleh peminjam
- Data      : id_pinjam, tgl_kembali, kondisi_akhir, catatan, petugas_id
- Aturan    : hanya untuk peminjaman berstatus aktif; keterlambatan dikenakan denda; kondisi rusak memindahkan unit ke status perbaikan
- Volume    : ±60 transaksi/hari
- Sumber    : hasil wawancara
- Prioritas : wajib

### KD-07 Perhitungan denda

- Deskripsi : mencatat denda atas keterlambatan pengembalian atau kerusakan alat
- Data      : id_denda, id_pinjam, hari_terlambat, nominal, status_bayar
- Aturan    : denda dihitung per hari keterlambatan dikali tarif denda standar
- Volume    : ±5 kejadian/minggu
- Sumber    : kalkulasi sistem
- Prioritas : sedang

### KD-08 Perbaikan alat lab

- Deskripsi : mencatat riwayat pemeliharaan dan perbaikan unit alat yang rusak
- Data      : id_perbaikan, id_unit, tgl_mulai, tgl_selesai, catatan
- Aturan    : selama masa perbaikan, status unit fisik terkunci dan tidak bisa dipinjam
- Volume    : ±10 record/bulan
- Sumber    : laporan teknisi
- Prioritas : sedang

---