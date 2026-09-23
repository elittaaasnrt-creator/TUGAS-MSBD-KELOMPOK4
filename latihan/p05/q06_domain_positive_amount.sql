

-- Percobaan 1: Memasukkan pembayaran bernilai nol
INSERT INTO lab5.payment_tx (payment_id, amount)
VALUES (9991, 0);

-- Percobaan 2: Memasukkan pembayaran bernilai negatif
INSERT INTO lab5.payment_tx (payment_id, amount)
VALUES (9992, -1000);

