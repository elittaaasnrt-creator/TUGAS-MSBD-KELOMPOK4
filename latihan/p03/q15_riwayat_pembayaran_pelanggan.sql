-- Diminta: untuk setiap pelanggan, tampilkan urutan pembayaran, jarak
-- hari sejak pembayaran sebelumnya, dan total belanja pelanggan sebagai
-- kolom pendamping pada setiap baris.
-- Dipilih: PARTITION BY customer_id untuk semua window function; ROW_NUMBER
-- untuk urutan pembayaran, LAG untuk jarak hari dari pembayaran sebelumnya,
-- dan SUM dengan frame seluruh partisi (ROWS BETWEEN UNBOUNDED PRECEDING
-- AND UNBOUNDED FOLLOWING) untuk total belanja yang sama di semua baris
-- pelanggan tersebut.
-- Alternatif: subquery terpisah untuk menghitung total belanja per
-- pelanggan lalu di-JOIN balik; tidak dipilih karena window function bisa
-- menghasilkan kolom pendamping tanpa join tambahan, dalam satu SELECT.

SELECT 
    p.payment_id,
    p.customer_id,
    c.first_name || ' ' || c.last_name AS nama_pelanggan,
    p.payment_date,
    p.amount,
    ROW_NUMBER() OVER (
        PARTITION BY p.customer_id 
        ORDER BY p.payment_date, p.payment_id
    ) AS urutan_pembayaran,
    DATE(p.payment_date) - DATE(
        LAG(p.payment_date) OVER (
            PARTITION BY p.customer_id 
            ORDER BY p.payment_date, p.payment_id
        )
    ) AS jarak_hari,
    SUM(p.amount) OVER (
        PARTITION BY p.customer_id
    ) AS total_belanja_pelanggan
FROM payment p
JOIN customer c ON p.customer_id = c.customer_id
ORDER BY p.customer_id, p.payment_date, p.payment_id;
