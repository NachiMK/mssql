-- 7-webinar_copy_review.sql
select trim(c.nspname) || '.' || trim(b.relname) as "table", 
	sum(d.distinct_files) as files_scanned, sum(d.MB_scanned) as MB_scanned, 
	(sum(d.distinct_files)::numeric(19,3)/count(distinct a.query)::numeric(19,3))::numeric(19,3) as avg_files_per_copy, 
	(sum(d.MB_scanned)/sum(d.distinct_files)::numeric(19,3))::numeric(19,3) as avg_file_size_mb, 
	count(distinct a.query) no_of_copy, max(a.query) as sample_query
from (	select query, tbl, sum(rows) as rows_inserted, max(endtime) as endtime, 
		datediff('microsecond',min(starttime),max(endtime)) as insert_micro 
		from  stl_insert group by query, tbl) a,
		pg_class b, pg_namespace c ,
		(select a.query, count(distinct b.bucket||b.key) as distinct_files, 
			sum(a.lines) as lines_scanned, sum(a.bytes)/1024/1024 as MB_scanned, sum(a.loadtime) as load_micro 
		from stl_file_scan a, stl_s3client b where b.http_method = 'GET' and a.query = b.query group by a.query) d
where a.tbl = b.oid and b.relnamespace = c.oid and d.query = a.query
group by  1
order by 3 desc;