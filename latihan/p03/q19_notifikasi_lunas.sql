-- Diminta: Menampilkan notifikasi berstatus lunas, mengekstrak properti JSONB ke kolom relasional dengan tipe data yang sesuai, serta membuat indeks GIN.
-- Dipilih: Operator containment JSONB (@>) untuk filtering performan status lunas, operator extraction (->>) dengan type casting (::numeric) untuk jumlah pembayaran, dan perintah CREATE INDEX USING GIN.
-- Alternatif: Filtering dengan `payload->>'status' = 'lunas'`; tidak dipilih karena operator containment (@>) dapat memanfaatkan keunggulan struktur indeks GIN secara optimal.

SELECT 
  payload->>'trx' AS nomor_transaksi,
  payload->'pelanggan'->>'kota' AS kota_pelanggan,
  (payload->>'jumlah')::numeric AS jumlah
FROM notifikasi
WHERE payload @> '{"status": "lunas"}';

CREATE INDEX idx_notifikasi_payload ON notifikasi USING gin (payload);