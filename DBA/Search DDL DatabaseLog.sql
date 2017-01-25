
SELECT * FROM 
(
SELECT 
        Post.value('(text())[1]', 'DATETIME') as PostTime
	   ,EventInstance
	   ,ET.value('(text())[1]', 'NVARCHAR(100)') AS EventType
FROM 
       mnDBA.dbo.DDLDatabaseLog 
	   CROSS APPLY EventInstance.nodes('/EVENT_INSTANCE/PostTime') AS EventChg(Post)
	   CROSS APPLY EventInstance.nodes('/EVENT_INSTANCE/EventType') AS EventType(ET)
)  as Result
WHERE	PostTime > '1/1/2016'
AND		Result.PostTime < '5/30/2016'
AND		Result.EventType LIKE '%PROCEDURE%'
ORDER BY Result.PostTime
