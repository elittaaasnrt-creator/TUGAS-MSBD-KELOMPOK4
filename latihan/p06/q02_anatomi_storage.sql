-- Q2 ? Tuple per halaman (lab6.event_log)
SELECT count(*) AS jumlah_halaman,
       round(avg(n), 2) AS rata_tuple_per_halaman,
       min(n) AS min_tuple, max(n) AS max_tuple
FROM (
  SELECT (ctid::text::point)[0]::int AS blk, count(*) AS n
  FROM lab6.event_log GROUP BY 1
) t;
