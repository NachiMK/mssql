-- 6-webinar_redundant_complyze.sql
SELECT
	a.userid, a.query, round(b.comp_time::float/1000::float,2) comp_sec, round(a.copy_time::float/1000::float,2) load_sec, 
	round(100*b.comp_time::float/(b.comp_time + a.copy_time)::float,2) ||'%' pct_complyze,
	substring(q.querytxt,1,50)
FROM
	(select userid, query, xid, datediff(ms,starttime,endtime) copy_time from stl_query q where (querytxt ilike 'copy %from%') 
	AND  exists  (select 1 from stl_commit_stats cs where cs.xid=q.xid)
	AND  exists  (select xid from stl_query where query in (select distinct query from stl_load_commits))) a
LEFT JOIN 
	(select xid, sum(datediff(ms,starttime,endtime)) comp_time 
	from stl_query q where (querytxt like 'COPY ANALYZE %' or querytxt like 'analyze compression phase %') 
		AND  exists  (select 1 from stl_commit_stats cs where cs.xid=q.xid)
		AND  exists  (select xid from stl_query where query in (select distinct query from stl_load_commits))
	group by 1) b ON b.xid = a.xid
JOIN stl_query q on q.query = a.query
where (b.comp_time is not null)
order by 6,5;