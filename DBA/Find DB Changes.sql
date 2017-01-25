DECLARE @objname varchar(max),@username varchar(max),@dbname varchar(max)  
--set @objname='up_Refreash_MemberAttributeFlat_20_v5'  
--set @username='%pkats%'  set @dbname='mnMailLog'   
set @dbname = '%'+ isnull(@dbname,'mnImail3')+'%'  
set @objname='%'+ isnull(@objname,'up_Mail_Conversation_Inbox_Member_List')+'%'  
set @username='%'+ isnull(@username,'nmuthukumar')+'%'   
 
SELECT  
EventID
,  eventinstance.value('(//PostTime)[1]', 'datetime') AS dt
,  EventInstance.value('(//EventType)[1]', 'nvarchar(max)') AS EventType
,  eventinstance.value('(//LoginName)[1]', 'nvarchar(max)') AS loginname
,  eventinstance.value('(//DatabaseName)[1]', 'nvarchar(max)') AS DatabaseName
,  EventInstance.value('concat((//SchemaName)[1], ".", (//ObjectName)[1])', 'nvarchar(60)') AS ObjectName
,  eventinstance.value('(//CommandText)[1]', 'nvarchar(max)') AS EventType
,  eventinstance
 
FROM mndba.dbo.[DDLDatabaseLog] (nolock)
WHERE  eventinstance.value('(//ObjectName)[1]', 'nvarchar(max)') like @objname
and  eventinstance.value('(//LoginName)[1]', 'nvarchar(max)')  like @username
and  eventinstance.value('(//DatabaseName)[1]', 'nvarchar(max)')  like @dbname
order by 1 desc 
