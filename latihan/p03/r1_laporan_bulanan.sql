WITH bulanan AS (
    SELECT 
        date_trunc('month', p.payment_date)::date AS bulan,
        c.name AS kategori,
        sum(p.amount) AS pendapatan
    FROM payment p
    JOIN rental r ON r.rental_id = p.rental_id
    JOIN inventory i ON i.inventory_id = r.inventory_id
    JOIN film_category fc ON fc.film_id = i.film_id
    JOIN category c ON c.category_id = fc.category_id
    GROUP BY 1, 2
)
SELECT 
    bulan,
    kategori,
    pendapatan,
    RANK() OVER (
        PARTITION BY bulan 
        ORDER BY pendapatan DESC
    ) AS peringkat,
    LAG(pendapatan) OVER (
        PARTITION BY kategori 
        ORDER BY bulan
    ) AS bulan_lalu,
    ROUND(
        (pendapatan - LAG(pendapatan) OVER (PARTITION BY kategori ORDER BY bulan)) / 
        NULLIF(LAG(pendapatan) OVER (PARTITION BY kategori ORDER BY bulan), 0) * 100, 
        2
    ) AS pertumbuhan_persen,
    SUM(pendapatan) OVER (
        PARTITION BY kategori 
        ORDER BY bulan 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS pendapatan_kumulatif,
    ROUND(
        (pendapatan / SUM(pendapatan) OVER (PARTITION BY bulan)) * 100, 
        2
    ) AS porsi_persen
FROM bulanan
ORDER BY bulan, peringkat;