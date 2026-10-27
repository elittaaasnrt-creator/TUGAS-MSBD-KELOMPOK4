-- Diminta: membuktikan domain positive_amount menolak nilai nol dan negatif.
-- Dipilih: insert langsung ke payment_tx dengan rental_id yang sudah ada (dari Q2), payment_id dibiarkan auto-generate.
-- Alternatif: mengisi payment_id manual; tidak dipilih karena kolom itu GENERATED ALWAYS AS IDENTITY dan akan ditolak tanpa OVERRIDING SYSTEM VALUE.

-- Percobaan 1: nilai nol
INSERT INTO lab5.payment_tx (rental_id, amount) VALUES (1, 0);

-- Percobaan 2: nilai negatif
INSERT INTO lab5.payment_tx (rental_id, amount) VALUES (1, -1000);
