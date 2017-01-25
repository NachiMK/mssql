USE distribution
GO

select * from dbo.MSarticles
where article_id in (
    select article_id from MSrepl_commands
    where xact_seqno =  0x000053F90000D025000100000000)

--And this will give you the command (and the primary key (ie the row) the command was executing against)
exec sp_browsereplcmds 
@xact_seqno_start = '0x00003D610002ECB7000100000000',
--@article_id = 19 
@xact_seqno_end   = '0x00003D610002ECB7000100000000'

SELECT CONVERT(BIGINT, 0x0000F2EE00000702000100000000)

SELECT TOP 100 agent_id,publisher_database_id,publisher_db,command_id ,*
FROM MSrepl_errors a with (nolock)
JOIN MSdistribution_history with (nolock) ON a.id = MSdistribution_history.error_id
JOIN MSdistribution_agents with (nolock) ON MSdistribution_agents.id = MSdistribution_history.agent_id
WHERE start_time > DATEADD(mi, -10, GETDATE())
ORDER BY  a.id desc, a.time DESC

EXEC sp_setsubscriptionxactseqno  @publisher =  'LACUBEDATA01' 
        ,  @publisher_db =  'DataWarehouse' 
        ,  @publication =  'LACUBEDATA01-DataWarehouse-DataWarehouse Replica-OCSQLFINANCE01-348' 
        ,  @xact_seqno =  0x000C2F240000AEA000D600000000


EXEC sp_helpsubscriptionerrors @publisher = 'LASQL08', @publisher_db = 'mnMember24', @publication = 'mnMember24 LASQLPRODFLAT01 Replication', @subscriber = 'LASQLPRODFLAT01', @subscriber_db = 'mnMember24'

EXEC sp_helpsubscriptionerrors @publisher = 'LASQL02', @publisher_db = 'mnMember5', @publication = 'mnMember5 LASQLPRODFLAT01 Replication', @subscriber = 'LASQLPRODFLAT01', @subscriber_db = 'mnMember5'

EXEC sp_helpsubscriptionerrors @publisher = 'LASQL06', @publisher_db = 'mnMember13', @publication = 'mnMember13 LASQLPRODFLAT01 Replication', @subscriber = 'LASQLPRODFLAT01', @subscriber_db = 'mnMember13'

EXEC sp_helpsubscriptionerrors @publisher = 'LASQL06', @publisher_db = 'mnMember14', @publication = 'mnMember14 LASQLPRODFLAT01 Replication', @subscriber = 'LASQLPRODFLAT01', @subscriber_db = 'mnMember14'

EXEC sp_helpsubscriptionerrors @publisher = 'LASQL10', @publisher_db = 'epRenewal', @publication = 'epRenewal Replication', @subscriber = 'LADBREPORT', @subscriber_db = 'epRenewal'

EXEC sp_helpsubscriptionerrors @publisher = 'LASQL10', @publisher_db = 'epRenewal', @publication = 'epRenewal Replication to LACUBEDATA01', @subscriber = 'LACUBEDATA01', @subscriber_db = 'epRenewal'

EXEC sp_helpsubscriptionerrors @publisher = 'LASQLPRODFLAT01', @publisher_db = 'mnMember_ProdFlat', @publication = 'mnMember_ProdFlat Reduced Columns Replication LASQLPRODFLAT02', @subscriber = 'LASQLPRODFLAT02', @subscriber_db = 'mnMember_ProdFlat'

EXEC sp_helpsubscriptionerrors @publisher = 'LADATAMART01', @publisher_db = 'mnMember_ProdFlat', @publication = 'mnMember_ProdFlat Replication to LARESEARCHDB01 Insert Only', @subscriber = 'LARESEARCHDB01', @subscriber_db = 'mnMember_ProdFlat_scd'


--EXEC sys.sp_MSstartdistribution_agent
--	@publisher = 'LACUBEDATA01'
--   , -- sysname
--	@publisher_db = 'DataWarehouse'
--   , -- sysname
--	@publication = 'DataWarehouse Replication to LADATAMART01'
--   , -- sysname
--	@subscriber = 'LADATAMART01'
--   , -- sysname
--	@subscriber_db = 'DataWarehouse_Adhoc' -- sysname



IF OBJECT_ID('tempdb.dbo.#t1') IS NOT NULL
    DROP TABLE #t1;
WITH    MaxXact ( ServerName, PublisherDBID, XactSeqNo )
          AS ( SELECT   S.name ,
                        DA.publisher_database_id ,
                        MAX(H.xact_seqno)
               FROM     distribution.dbo.MSdistribution_history H WITH ( NOLOCK )
                        INNER JOIN distribution.dbo.MSdistribution_agents DA
                        WITH ( NOLOCK ) ON DA.id = H.agent_id
                        INNER JOIN master.sys.servers S WITH ( NOLOCK ) ON S.server_id = DA.subscriber_id
               GROUP BY S.name ,
                        DA.publisher_database_id
             )
    SELECT  MX.ServerName ,
            MX.PublisherDBID ,
            MSD.publisher_db ,
            COUNT(*) AS CommandsNotReplicated
    INTO    #t1
    FROM    distribution.dbo.MSrepl_commands C WITH ( NOLOCK )
            RIGHT JOIN MaxXact MX ON MX.XactSeqNo < C.xact_seqno
                                     AND MX.PublisherDBID = C.publisher_database_id
            LEFT JOIN distribution.dbo.MSpublisher_databases AS MSD ON MSD.id = C.publisher_database_id
    GROUP BY MX.ServerName ,
            MX.PublisherDBID ,
            MSD.publisher_db
    ORDER BY 4 DESC ,
            1 ,
            2;


 
WAITFOR DELAY '00:01';
 
IF OBJECT_ID('tempdb.dbo.#t2') IS NOT NULL
    DROP TABLE #t2;
WITH    MaxXact ( ServerName, PublisherDBID, XactSeqNo )
          AS ( SELECT   S.name ,
                        DA.publisher_database_id ,
                        MAX(H.xact_seqno)
               FROM     distribution.dbo.MSdistribution_history H WITH ( NOLOCK )
                        INNER JOIN distribution.dbo.MSdistribution_agents DA
                        WITH ( NOLOCK ) ON DA.id = H.agent_id
                        INNER JOIN master.sys.servers S WITH ( NOLOCK ) ON S.server_id = DA.subscriber_id
               GROUP BY S.name ,
                        DA.publisher_database_id
             )
    SELECT  MX.ServerName ,
            MX.PublisherDBID ,
            MSD.publisher_db ,
            COUNT(*) AS CommandsNotReplicated
    INTO    #t2
    FROM    distribution.dbo.MSrepl_commands C WITH ( NOLOCK )
            RIGHT JOIN MaxXact MX ON MX.XactSeqNo < C.xact_seqno
                                     AND MX.PublisherDBID = C.publisher_database_id
            LEFT JOIN distribution.dbo.MSpublisher_databases AS MSD ON MSD.id = C.publisher_database_id
    GROUP BY MX.ServerName ,
            MX.PublisherDBID ,
            MSD.publisher_db
    ORDER BY 4 DESC ,
            1 ,
            2;

SELECT * FROM #T1 T1
JOIN #t2 T2 ON T2.publisherDBID = T1.publisherDBID AND T2.ServerName = T1.servername

SELECT * FROM #T1 WHERE publisherDBID = 260
SELECT * FROM #T2




SELECT TOP 100 * FROM distribution.dbo.MSdistribution_history WITH (READUNCOMMITTED) WHERE start_time > '6/20/2016 18:00'

SELECT COUNT(*) FROM distribution.dbo.MSrepl_commands M WITH (NOLOCK) WHERE article_id = 1 AND publisher_database_id = 271

SELECT * FROM distribution.dbo.MSrepl_commands M WITH (NOLOCK) WHERE article_id = 1 AND publisher_database_id = 271

select * From distribution..MSsubscriptions

-- MARK subscription as Active
/*
IF exists (select 1 from distribution..MSsubscriptions where status = 0)
begin
UPDATE distribution..MSsubscriptions
SET STATUS = 2
WHERE publisher_id = 0
    AND publisher_db = 'mnMember_ProdFlat'
    AND publication_id = 4
    AND subscriber_id = 17
    AND subscriber_db = 'mnMember_ProdFlat_scd'
	AND status = 0
end
else
begin
print 'The subscription is not INACTIVE.. you are good for now .... !!'
END
*/

-- Fix any data issues
SELECT MemberID, AttributeGroupID, Value FROM LASQL07.mnMember23.dbo.MemberAttributeInt	 WHERE MemberID = 115326406 
EXCEPT
SELECT MemberID, AttributeGroupID, Value FROM LASQL08.mnMember23.dbo.MemberAttributeInt	 WHERE MemberID = 115326406

SELECT MemberID, AttributeGroupID, Value FROM LASQL08.mnMember23.dbo.MemberAttributeInt	 WHERE MemberID = 115326406 
EXCEPT
SELECT MemberID, AttributeGroupID, Value FROM LASQL07.mnMember23.dbo.MemberAttributeInt	 WHERE MemberID = 115326406

SELECT rowid, MemberID, AttributeGroupID, Value FROM LASQL08.mnMember23.dbo.MemberAttributeInt	 WHERE MemberID = 115326406
EXCEPT
SELECT rowid, MemberID, AttributeGroupID, Value FROM LASQLPRODFLAT01.mnMember23.dbo.MemberAttributeInt	 WHERE MemberID = 115326406

SELECT rowid, MemberID, AttributeGroupID, Value FROM LASQLPRODFLAT01.mnMember23.dbo.MemberAttributeInt	 WHERE MemberID = 115326406
EXCEPT
SELECT rowid, MemberID, AttributeGroupID, Value FROM LASQL08.mnMember23.dbo.MemberAttributeInt	 WHERE MemberID = 115326406


-- UPDATE LASQLPRODFLAT01.mnmember23.dbo.MemberAttributeInt SET Value = 0 WHERE rowid = 35329809 AND MemberID = 115326406 AND AttributeGroupID = 122
-- DELETE LASQLPRODFLAT01.mnmember23.dbo.MemberAttributeInt WHERE rowid = 45417530 AND MemberID = 115326406 
