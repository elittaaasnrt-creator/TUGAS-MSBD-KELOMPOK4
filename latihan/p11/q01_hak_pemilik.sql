-- Diminta: cabut UPDATE dari skema_owner, uji, beri kembali oleh pemilik sendiri, uji lagi.
-- Dipilih: REVOKE sebagai superuser, GRANT sebagai skema_owner, untuk membuktikan
--          pemilik selalu bisa memulihkan haknya sendiri.
-- Alternatif: hanya REVOKE tanpa uji; tidak dipilih karena tidak membuktikan apa-apa.
REVOKE UPDATE ON lab11.pelanggan FROM skema_owner;
SET ROLE skema_owner;
BEGIN; UPDATE lab11.pelanggan SET kota = kota WHERE id = 3; ROLLBACK;  -- ditolak
GRANT UPDATE ON lab11.pelanggan TO skema_owner;                         -- oleh pemilik sendiri
BEGIN; UPDATE lab11.pelanggan SET kota = kota WHERE id = 3; ROLLBACK;  -- berhasil
RESET ROLE;
-- HASIL 1 (skema_owner, setelah REVOKE): ERROR:  permission denied for table pelanggan
-- HASIL 2 (skema_owner, setelah GRANT sendiri): UPDATE 1
-- Penjelasan: pemilik objek otomatis memegang semua hak beserta wewenang menggrantnya.
-- REVOKE hanya menghapus entri di ACL; wewenang memberi hak melekat pada kepemilikan,
-- sehingga pemilik bisa menulis GRANT untuk dirinya sendiri kapan saja.