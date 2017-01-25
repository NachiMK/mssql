--Backup
/*
DECLARE @dbname sysname
,@ServerName varchar(20)
,@path varchar(100)
,@localpath varchar(100)
,@dir varchar(100)
,@folder varchar(1000)

SET @dir = '\\lanexenta03-corp.matchnet.com\corp_backups\SQL'
SET @localpath = 'C:\SQL_BACKUP\system\'

SET @servername = @@servername

set @ServerName=REPLACE(@servername,'\','_')
SET @folder = 'full'

SET @path = @dir + '\' + @servername + '\' + @folder 

EXEC mnDBA.dbo.usp_Backup_call @path = @path , @localpath = @localpath ,  @bkpType = 'FULL', @retention = 3, @liteSpeed = 'Y',@freespaceMBrequired = 10000
					, @backup_databases = 'distribution'
	

*/

-- status
SELECT command,
            s.text,
            start_time,
            percent_complete, 
            CAST(((DATEDIFF(s,start_time,GetDate()))/3600) as varchar) + ' hour(s), '
                  + CAST((DATEDIFF(s,start_time,GetDate())%3600)/60 as varchar) + 'min, '
                  + CAST((DATEDIFF(s,start_time,GetDate())%60) as varchar) + ' sec' as running_time,
            CAST((estimated_completion_time/3600000) as varchar) + ' hour(s), '
                  + CAST((estimated_completion_time %3600000)/60000 as varchar) + 'min, '
                  + CAST((estimated_completion_time %60000)/1000 as varchar) + ' sec' as est_time_to_go,
            dateadd(second,estimated_completion_time/1000, getdate()) as est_completion_time 
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) s
WHERE r.command in ('RESTORE DATABASE', 'BACKUP DATABASE', 'RESTORE LOG', 'BACKUP LOG')

