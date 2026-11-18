-- Diminta: jalankan satu permintaan penghapusan (catat permintaan, hapus transaksi
--          lalu pelanggan), kemudian hitung sisa data subjek di tabel utama,
--          transaksi, dan jejak audit.
-- Dipilih: menghapus subjek pelanggan id IN (12, 13) beserta catatan transaksinya,
--          lalu menghitung sisa kemunculan data pada ketiga tabel tersebut.
-- Alternatif: hanya menghapus baris di tabel pelanggan; tidak dipilih karena melanggar
--             kendala foreign key dari lab11.transaksi.

INSERT INTO lab11.permintaan_hapus (pelanggan_id, alasan, status)
VALUES (12, 'Permintaan penghapusan data oleh subjek data', 'SELESAI'),
       (13, 'Permintaan penghapusan data oleh subjek data', 'SELESAI');

DELETE FROM lab11.transaksi WHERE pelanggan_id IN (12, 13);
DELETE FROM lab11.pelanggan WHERE id IN (12, 13);

SELECT count(*) AS sisa_tabel_utama FROM lab11.pelanggan WHERE id IN (12, 13);
SELECT count(*) AS sisa_transaksi   FROM lab11.transaksi WHERE pelanggan_id IN (12, 13);
SELECT count(*) AS sisa_jejak_audit FROM lab11.jejak_audit
WHERE kunci IN ('12', '13') AND nilai_lama ? 'nik';

-- HASIL:
-- sisa_tabel_utama = 0
-- sisa_transaksi   = 0
-- sisa_jejak_audit = 2  (data NIK lama tetap tersimpan di kolom jsonb nilai_lama!)
-- Penjelasan: penghapusan dari tabel operasional (pelanggan dan transaksi) berhasil menihilkan
-- data aktif subjek (0 baris), tetapi trigger audit otomatis merekam seluruh salinan baris
-- sebelum dihapus (to_jsonb(OLD)) ke kolom nilai_lama pada lab11.jejak_audit, sehingga
-- data pribadi sensitif seperti NIK masih bertahan di log audit.