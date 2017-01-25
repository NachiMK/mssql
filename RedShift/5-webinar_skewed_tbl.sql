-- 5-webinar_skewed_tbl.sql
SELECT schema || '.' || "table" AS "table", size, diststyle, skew_rows::bigint as rows_skew,
	ROUND(CAST(max_blocks_per_slice - min_blocks_per_slice AS FLOAT) / GREATEST(NVL (min_blocks_per_slice,0)::int,1),2) AS storage_skew,
	ROUND(CAST(100*dist_slice AS FLOAT) /(SELECT COUNT(DISTINCT slice) FROM stv_slices),2) pct_slices_populated
FROM svv_table_info ti
JOIN (SELECT tbl, MIN(c) min_blocks_per_slice, MAX(c) max_blocks_per_slice, COUNT(DISTINCT slice) dist_slice
      FROM (SELECT b.tbl, b.slice, COUNT(*) AS c
            FROM STV_BLOCKLIST b
            GROUP BY b.tbl, b.slice)
      WHERE tbl IN (SELECT table_id FROM svv_table_info)
      GROUP BY tbl) iq ON iq.tbl = ti.table_id
WHERE skew_rows > 2
ORDER BY 4 DESC;