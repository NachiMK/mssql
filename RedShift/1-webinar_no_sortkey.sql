-- 1-webinar_no_sortkey.sql
select 
	ti.schema ||'.'||ti."table" as "table", 
	substring(trim(info),1,180) as filter, 
	sum(datediff(seconds,starttime,case when starttime > endtime then starttime else endtime end)) as secs, 
	count(distinct i.query) as num, 
	max(i.query) as query
from 
	stl_explain p
join stl_plan_info i on ( i.userid=p.userid and i.query=p.query and i.nodeid=p.nodeid )
join stl_scan s on (s.userid=i.userid and s.query=i.query and s.segment=i.segment and s.step=i.step)
join svv_table_info ti on (ti.table_id = s.tbl)
where s.starttime > dateadd(day, -7, current_Date)
	and s.perm_table_name not like 'Internal Worktable%'
	and p.info <> ''
	and ti.sortkey1 is null
group by 1,2 order by 1, 4 desc , 3 desc;
