/****** Script for SelectTopNRows command from SSMS  ******/
SELECT		CONVERT(DATE, collection_time), host_name, database_name, session_id, Cnt = COUNT(*)
FROM		[DBAUtil].[dbo].[WhoIsActive_Output] WITH (READUNCOMMITTED)
WHERE		1 = 1
AND			(
				(database_name NOT LIKE 'RW5%')
				AND
				(database_name NOT LIKE '%REPL%')
				AND
				(database_name != 'DataCollection')
				AND
				(database_name != 'InDAta')
			)
AND			CONVERT(DATE, collection_time) = CONVERT(DATE, GETDATE())
GROUP BY	CONVERT(DATE, collection_time), host_name, database_name, session_id
HAVING		COUNT(*) > 1
ORDER BY	Cnt DESC,host_name, CONVERT(DATE, collection_time), database_name, session_id

SELECT	*
FROM	DBAUtil.dbo.WhoIsActive_Output AS WIA WITH (READUNCOMMITTED)
WHERE	WIA.session_id	= 69
AND		host_name		= 'CABIDBP-N1'
AND		database_name	= 'QnA'
AND		CONVERT(DATE, collection_time) = CONVERT(DATE, GETDATE())

SELECT	*
FROM	DBAUtil.dbo.WhoIsActive_Output AS WIA WITH (READUNCOMMITTED)
WHERE	collection_time > '2014-11-12 12:14:58'
