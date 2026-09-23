-- Diminta: membuktikan enum rental_status menolak nilai tak dikenal, lalu menambah nilai baru dengan ALTER TYPE.
-- Dipilih: uji UPDATE dengan status 'EXPIRED' sebelum dan sesudah ALTER TYPE ... ADD VALUE.
-- Alternatif: membuat ulang tipe enum dari awal dengan nilai lengkap; tidak dipilih karena ALTER TYPE ADD VALUE lebih aman untuk tipe yang sudah dipakai tabel.

-- Percobaan 1: Mengubah status menjadi EXPIRED
UPDATE lab5.rental_tx
SET status = 'EXPIRED'
WHERE rental_id = 1;

-- Menambahkan nilai EXPIRED ke enum
ALTER TYPE lab5.rental_status
ADD VALUE 'EXPIRED';

-- Percobaan 2: Mengulangi UPDATE setelah enum diperbarui
UPDATE lab5.rental_tx
SET status = 'EXPIRED'
WHERE rental_id = 1;

-- Catatan hasil:
-- Percobaan pertama seharusnya gagal karena EXPIRED belum terdaftar.
-- Setelah ALTER TYPE, percobaan kedua seharusnya berhasil.