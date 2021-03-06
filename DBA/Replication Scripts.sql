USE Distribution 
GO 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
/*
	Script to find all Subscriptions and publications
*/
IF OBJECT_ID('tempdb..#PubsAndSubs') IS NOT NULL
	DROP TABLE #PubsAndSubs
SELECT	DISTINCT Publisher = PS.srvname, P.publisher_db, P.publication, Subscriber = SS.srvname, S.subscriber_db 
		,P.publisher_id
		,S.subscriber_id
INTO	#PubsAndSubs
FROM	dbo.MSpublications			P
JOIN	dbo.MSsubscriptions			S	ON	S.publication_id = P.publication_id
										AND	S.publisher_id = P.publisher_id
JOIN	master..sysservers			PS	ON	PS.srvid	=	P.publisher_id
JOIN	master..sysservers			SS	ON	SS.srvid	=	S.subscriber_id
ORDER BY Publisher, P.publisher_db, Subscriber, S.subscriber_db


-- Generate Stop Dist Agent Script
SELECT	Publisher ,
      	publisher_db ,
      	publication ,
      	Subscriber ,
      	subscriber_db ,
      	publisher_id ,
      	subscriber_id 
		--,StartScript = 'EXEC dbo.sp_MSstartdistribution_agent @publisher = ''' + Publisher + ''''
		--				+ ',@publisher_db = ''' + publisher_db + '''' 
		--				+ ',@publication = N''' + publication + ''''
		--				+ ',@subscriber = N''' + Subscriber + ''''
		--				+ ',@subscriber_db = N''' + Subscriber_db + ''''

		,StopScript = 'EXEC dbo.sp_MSstopdistribution_agent @publisher = ''' + Publisher + ''''
						+ ',@publisher_db = ''' + publisher_db + '''' 
						+ ',@publication = N''' + publication + ''''
						+ ',@subscriber = N''' + Subscriber + ''''
						+ ',@subscriber_db = N''' + Subscriber_db + ''''
FROM	#PubsAndSubs

-- Get the publication name based on article 
SELECT DISTINCT
		srv.srvname publication_server
	   ,a.publisher_db
	   ,p.publication publication_name
	   ,a.article
	   ,a.destination_object
	   ,ss.srvname subscription_server
	   ,s.subscriber_db
	   ,da.name AS distribution_agent_job_name
FROM	MSArticles a
JOIN	MSpublications p ON a.publication_id = p.publication_id
JOIN	MSsubscriptions s ON p.publication_id = s.publication_id
JOIN	master..sysservers ss ON s.subscriber_id = ss.srvid
JOIN	master..sysservers srv ON srv.srvid = p.publisher_id
JOIN	MSdistribution_agents da ON da.publisher_id = p.publisher_id
									AND da.subscriber_id = s.subscriber_id
ORDER BY 1
	   ,2
	   ,3

-- SCript to stop Dist agent
--EXEC dbo.sp_MSstopdistribution_agent 
--		 @publisher = 'LASQL02'
--		,@publisher_db = 'mnActivityRecoring'
--		,@publication = N'mnActivityRecoring Replication'
--		,@subscriber = N'LADBREPORT'
--		,@subscriber_db = N'mnActivityRecording'
--		GO
