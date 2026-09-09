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