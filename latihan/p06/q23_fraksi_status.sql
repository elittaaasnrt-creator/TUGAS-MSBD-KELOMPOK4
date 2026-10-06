SELECT status, count(*), count(*)::float / (SELECT count(*) FROM lab6.event_log) AS fraksi
FROM lab6.event_log 
GROUP BY status;