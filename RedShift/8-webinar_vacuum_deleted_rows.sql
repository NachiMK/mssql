-- 8-webinar_vacuum_deleted_rows.sql
select trim(s.perm_table_name) as table,
	(sum(abs(datediff(seconds, coalesce(s.starttime),
		case when coalesce(s.endtime) > coalesce(s.starttime) THEN coalesce(s.endtime)
		ELSE coalesce(s.starttime) END )))/60)::numeric(24,0) as minutes,
       sum(coalesce(s.rows)) as rows, trim(split_part(l.event,':',1)) as event,
       max(l.query) as sample_query, count(distinct l.query)
from stl_alert_event_log as l
left join stl_scan as s on s.query = l.query and s.slice = l.slice and s.segment = l.segment
where l.userid>1
and  l.event_time >= dateadd(day, -7, current_Date)
and s.perm_table_name not like 'volt_tt%' and s.perm_table_name not like 'Internal%'
and event ilike '%deleted%'
group by 1,4 order by 2 desc, 6 desc;