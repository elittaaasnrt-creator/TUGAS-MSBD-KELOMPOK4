-- Q28: Overhead Ukuran Total Tabel vs Index
SELECT 
    pg_size_pretty(pg_relation_size('lab6.event_log')) AS ukuran_tabel_saja,
    pg_size_pretty(pg_indexes_size('lab6.event_log')) AS ukuran_total_index,
    pg_size_pretty(pg_total_relation_size('lab6.event_log')) AS ukuran_total_keseluruhan;
