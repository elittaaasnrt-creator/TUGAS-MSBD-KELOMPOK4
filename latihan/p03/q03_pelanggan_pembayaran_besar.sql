-- Diminta: nama pelanggan yang pernah melakukan pembayaran lebih dari
-- 9.99 dalam satu transaksi.
-- Dipilih: EXISTS berkorelasi, karena kita hanya perlu tahu "pernah ada"
-- pembayaran yang memenuhi syarat, bukan menghitung atau mengambil
-- nilainya, dan EXISTS bisa berhenti begitu menemukan satu baris cocok.
-- Alternatif: JOIN payment lalu DISTINCT customer; tidak dipilih karena
-- satu pelanggan bisa punya banyak pembayaran >9.99 sehingga JOIN akan
-- menggandakan baris pelanggan sebelum di-DISTINCT, lebih boros daripada EXISTS.

SELECT
    cu.first_name,
    cu.last_name
FROM customer cu
WHERE EXISTS (
    SELECT 1
    FROM payment p
    WHERE p.customer_id = cu.customer_id
      AND p.amount > 9.99
)
ORDER BY cu.last_name, cu.first_name;
