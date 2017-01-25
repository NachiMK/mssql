-- 2-webinar_sortkey.sql
select ti.schema||'.'||ti."table" as "table",
	ti.unsorted,
	ti.diststyle,
	ti.sortkey1,
	trim(a.typname) "type", 
	case s.is_rrscan when 'f' then 'FALSE' else 'TRUE' END rrscan, substring(trim(info),1,300) as filter,
	sum(datediff(seconds,starttime,case when starttime > endtime then starttime else endtime end)) as secs,
	count(distinct i.query) as num,
	max(i.query) as query
from stl_explain p
join stl_plan_info i on ( i.userid=p.userid and i.query=p.query and i.nodeid=p.nodeid  )
join stl_scan s on (s.userid=i.userid and s.query=i.query and s.segment=i.segment and s.step=i.step)
join svv_table_info ti on ti.table_id=s.tbl
left join (select attrelid,t.typname from pg_attribute a join pg_type t on t.oid=a.atttypid where attsortkeyord=1) a on a.attrelid=s.tbl
where s.starttime > dateadd(day, -7, current_Date)
	and s.perm_table_name not like 'Internal Worktable%'
	and p.info like 'Filter:%' and p.nodeid > 0
	and s.perm_table_name like '%' -- choose specific table to review
group by 1,2,3,4,5,6,7 
order by 1, 8 desc , 9 desc;