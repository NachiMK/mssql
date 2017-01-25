-- 9-webinar_vacuum_unsorted.sql
SELECT schema || '.' || "table" AS "table", size, sortkey1, unsorted 
FROM svv_table_info 
WHERE unsorted > 10 
ORDER BY size DESC;