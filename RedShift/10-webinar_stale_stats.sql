-- 10-webinar_stale_stats.sql
SELECT schema || '.' || "table" AS "table", size, stats_off 
FROM svv_table_info 
WHERE stats_off > 10 
ORDER BY size DESC;