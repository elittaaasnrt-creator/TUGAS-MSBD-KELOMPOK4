-- Q27: Pengujian write overhead (INSERT 200.000 baris)
\timing on

-- 1. Skenario tanpa index Tambahan
CREATE UNLOGGED TABLE lab6.test_no_idx (LIKE lab6.event_log INCLUDING ALL);
ALTER TABLE lab6.test_no_idx DROP CONSTRAINT test_no_idx_pkey;

INSERT INTO lab6.test_no_idx (customer_id, terjadi_pada, status, wilayah, kota, email, idempotency_key, jumlah, tags, payload)
SELECT customer_id, terjadi_pada, status, wilayah, kota, email, idempotency_key, jumlah, tags, payload
FROM lab6.event_log
LIMIT 200000;

-- 2. Skenario dengan 5-6 Index Terpasang
CREATE UNLOGGED TABLE lab6.test_with_idx (LIKE lab6.event_log INCLUDING ALL);

CREATE INDEX ON lab6.test_with_idx (customer_id, terjadi_pada DESC);
CREATE INDEX ON lab6.test_with_idx (terjadi_pada DESC) WHERE status='GAGAL';
CREATE INDEX ON lab6.test_with_idx (lower(email));
CREATE INDEX ON lab6.test_with_idx USING gin (payload jsonb_path_ops);
CREATE INDEX ON lab6.test_with_idx USING brin (terjadi_pada);

INSERT INTO lab6.test_with_idx (customer_id, terjadi_pada, status, wilayah, kota, email, idempotency_key, jumlah, tags, payload)
SELECT customer_id, terjadi_pada, status, wilayah, kota, email, idempotency_key, jumlah, tags, payload
FROM lab6.event_log
LIMIT 200000;

-- Bersihkan tabel pengujian sementara
DROP TABLE IF EXISTS lab6.test_no_idx;
DROP TABLE IF EXISTS lab6.test_with_idx;