-- Q1 ? Ukuran tabel dan rata-rata byte per baris (lab6.event_log)
SELECT count(*) AS baris,
  pg_size_pretty(pg_total_relation_size('lab6.event_log')) AS total,
  pg_size_pretty(pg_relation_size('lab6.event_log')) AS heap,
  pg_size_pretty(pg_indexes_size('lab6.event_log')) AS index,
  round(pg_relation_size('lab6.event_log')::numeric / count(*), 1) AS byte_per_baris_heap,
  round(pg_total_relation_size('lab6.event_log')::numeric / count(*), 1) AS byte_per_baris_total,
  round(avg(pg_column_size(e.*)), 1) AS byte_per_tuple_data
FROM lab6.event_log e;
