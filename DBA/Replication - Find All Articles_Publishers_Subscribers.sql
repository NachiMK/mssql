/*
	Script to Find all Articles/Publications/Publishers/Subscribers
	Run on Distribution server
*/
USE distribution 
GO 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
-- Get the publication name based on article 
SELECT DISTINCT
		Publication_server		=	srv.srvname 
	   ,a.Publisher_db
	   ,Publication_name		=	p.publication 
	   ,a.Article
	   ,a.Destination_object
	   ,Subscription_server		=	ss.srvname 
	   ,s.Subscriber_db
	   ,Distribution_Agent_job_name	=	da.name 
FROM	MSarticles a
JOIN	MSpublications p ON a.publication_id = p.publication_id
JOIN	MSsubscriptions s ON p.publication_id = s.publication_id
JOIN	master..sysservers ss ON s.subscriber_id = ss.srvid
JOIN	master..sysservers srv ON srv.srvid = p.publisher_id
JOIN	MSdistribution_agents da ON da.publisher_id = p.publisher_id
									AND da.subscriber_id = s.subscriber_id 
--WHERE ss.srvname = 'LADBREPORT'
ORDER BY 1
	   ,2
	   ,3  