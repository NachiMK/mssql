SELECT	ServerName,
		CheckDate = CONVERT(VARCHAR, CheckDate, 101),
		CheckHour = CONVERT(VARCHAR, DATEPART(hh, CheckDate)),
      	wait_type ,
      	wait_time_ms = AVG(wait_time_ms),
      	signal_wait_time_ms = AVG(signal_wait_time_ms),
      	waiting_tasks_count = AVG(waiting_tasks_count)
FROM	perf.WaitStats WHERE wait_type IN
(
 'PAGEIOLATCH_EX'
,'PAGEIOLATCH_UP'
,'WRITE_COMPLETION'
,'ASYNC_IO_COMPLETION'
,'BACKUPIO'
,'PAGEIOLATCH_SH'
,'IO_COMPLETION'
,'WRITELOG'
)
GROUP BY
		ServerName,wait_type, CONVERT(VARCHAR, CheckDate, 101), DATEPART(hh, CheckDate)
ORDER BY ServerName,wait_type, CONVERT(VARCHAR, CheckDate, 101) DESC, DATEPART(hh, CheckDate) asc
