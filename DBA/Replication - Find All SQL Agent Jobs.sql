/*
	Script to Find SQL Jobs for a Subscriber
	and we can use it to disable/enable the distribtion for any maintenance

	Run on Distribution server
*/
USE distribution 
GO 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
-- Get the publication name based on article 
SELECT DISTINCT
	     Distribution_Agent_job_name	=	da.name 
		,ScriptToDisable	=	'EXEC msdb.dbo.sp_update_job @job_name = ''' + da.name + ''', @enabled=0 '
		,ScriptToEnable		=	'EXEC msdb.dbo.sp_update_job @job_name = ''' + da.name + ''', @enabled=1 '
		,ScriptToStop		=	'EXEC msdb.dbo.sp_stop_job @job_name = ''' + da.name + ''''
		,ScriptToStart		=	'EXEC msdb.dbo.sp_start_job @job_name = ''' + da.name + ''''
FROM	MSarticles a
JOIN	MSpublications p ON a.publication_id = p.publication_id
JOIN	MSsubscriptions s ON p.publication_id = s.publication_id
JOIN	master..sysservers ss ON s.subscriber_id = ss.srvid
JOIN	master..sysservers srv ON srv.srvid = p.publisher_id
JOIN	MSdistribution_agents da ON da.publisher_id = p.publisher_id
									AND da.subscriber_id = s.subscriber_id 
WHERE ss.srvname = 'LADATAMART01'
ORDER BY 1
	   ,2
	   ,3  

