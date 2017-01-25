-- 0x000038950002A3D3000100000000
--{CALL [sp_MSdel_dboMemberAttributeInt] (41441576,140702172)}
--{CALL [sp_MSins_dboMemberAttributeInt] (41441576,140702172,122,0)}
--{CALL [sp_MSdel_dboMemberAttributeInt] (69491515,140702172)}

/*
{CALL [sp_MSdel_dboMemberAttributeInt] (41441576,140702172)}
{CALL [sp_MSins_dboMemberAttributeInt] (41441576,140702172,122,0)}
{CALL [sp_MSdel_dboMemberAttributeInt] (69682576,140702172)}
*/

/*
{CALL [sp_MSdel_dboMemberAttributeInt] (41441576,140702172)}
{CALL [sp_MSins_dboMemberAttributeInt] (41441576,140702172,122,0)}
{CALL [sp_MSdel_dboMemberAttributeInt] (70157799,140702172)}
*/
USE mnmember13
GO
EXEC sp_setsubscriptionxactseqno  @publisher =  'LASQL06' 
        ,  @publisher_db =  'mnMember13' 
        ,  @publication =  'mnMember13 LASQLPRODFLAT01 Replication' 
        ,  @xact_seqno =  0x00003CCC00021FA2000100000000

SELECT * FROM mnmember13.dbo.MemberAttributeInt WHERE MemberID = 140702172 AND rowid IN (41441576, 69629023)
SELECT * FROM mnmember13.dbo.MemberAttributeInt WHERE rowid IN (41441576, 69629023)
SELECT * FROM LASQL05.mnmember13.dbo.MemberAttributeInt WHERE MemberID = 140702172 AND rowid IN (41441576, 69629023)
SELECT * FROM LASQL06.mnmember13.dbo.MemberAttributeInt WHERE MemberID = 140702172 AND rowid IN (41441576, 69629023)

SELECT * FROM mnmember13.dbo.MemberAttributeInt WHERE MemberID = 140702172 AND AttributeGroupID = 122
SELECT * FROM LASQL06.mnmember13.dbo.MemberAttributeInt WHERE MemberID = 140702172 AND AttributeGroupID = 122
SELECT * FROM LASQL05.mnmember13.dbo.MemberAttributeInt WHERE MemberID = 140702172 AND AttributeGroupID = 122


BEGIN TRAN 
DELETE mnmember13.dbo.MemberAttributeInt WHERE rowid = 45878990 AND MemberID = 140702172
AND NOT EXISTS (SELECT * FROM LASQL06.mnmember13.dbo.MemberAttributeInt WHERE rowid = 45878990 AND MemberID = 140702172)

COMMIT

SELECT * FROM mnmember13.dbo.MemberAttributeInt M WHERE M.MemberID = 140702172 
AND NOT EXISTS (SELECT * FROM LASQL06.mnmember13.dbo.MemberAttributeInt WHERE MemberID = 140702172 AND rowid = M.rowid)

SELECT * FROM mnmember13.dbo.MemberAttributeInt M WHERE M.MemberID = 140702172 AND M.AttributeGroupID = 123

SELECT * FROM LASQL05.mnmember13.dbo.MemberAttributeInt M WHERE M.MemberID = 140702172 AND M.AttributeGroupID = 123

SELECT * FROM LASQL06.mnmember13.dbo.MemberAttributeInt M WHERE M.MemberID = 140702172 AND M.AttributeGroupID = 123



UPDATE mnmember13.dbo.MemberAttributeInt 
SET Value = 0
WHERE MemberID = 140702172 AND AttributeGroupID = 122

BEGIN tran
DELETE dbo.MemberAttributeInt WHERE MemberID = 140702172 AND rowid = 41441576

SET IDENTITY_INSERT dbo.MemberAttributeInt ON
INSERT INTO dbo.MemberAttributeInt
        ( rowid, MemberID, AttributeGroupID, Value )
SELECT rowid = 41441576, MemberID = 140702172, AttributeGroupID = 122, Value = 0

SET IDENTITY_INSERT dbo.MemberAttributeInt OFF

COMMIT


USE mnMember14
-- 
/*
{CALL [sp_MSdel_dboMemberAttributeInt] (32675761,113178637)}
{CALL [sp_MSins_dboMemberAttributeInt] (32675761,113178637,122,0)}
{CALL [sp_MSdel_dboMemberAttributeInt] (70352284,113178637)}
*/
EXEC sp_setsubscriptionxactseqno  @publisher =  'LASQL06' 
        ,  @publisher_db =  'mnMember14' 
        ,  @publication =  'mnMember14 LASQLPRODFLAT01 Replication' 
        ,  @xact_seqno =  0x00003D610002ECB7000100000000

SELECT * FROM mnmember14.dbo.MemberAttributeInt WHERE MemberID = 113178637 AND AttributeGroupID = 122
SELECT * FROM LASQL06.mnmember14.dbo.MemberAttributeInt WHERE MemberID = 113178637 AND AttributeGroupID = 122
SELECT * FROM LASQL05.mnmember14.dbo.MemberAttributeInt WHERE MemberID = 113178637 AND AttributeGroupID = 122

UPDATE mnmember14.dbo.MemberAttributeInt 
SET Value = 16
WHERE MemberID = 113178637 AND AttributeGroupID = 122


USE mnmember17
GO
/*
{CALL [sp_MSdel_dboMemberAttributeInt] (36072115,114971560)}
{CALL [sp_MSins_dboMemberAttributeInt] (36072115,114971560,122,0)}
{CALL [sp_MSdel_dboMemberAttributeInt] (71734395,114971560)}
*/
EXEC sp_setsubscriptionxactseqno  @publisher =  'LASQL06' 
        ,  @publisher_db =  'mnMember17' 
        ,  @publication =  'mnMember17 LASQLPRODFLAT01 Replication' 
        ,  @xact_seqno =  0x00003C58000084A5000100000000


SELECT * FROM mnmember17.dbo.MemberAttributeInt WHERE MemberID = 114971560 AND AttributeGroupID = 122
SELECT * FROM LASQL06.mnmember17.dbo.MemberAttributeInt WHERE MemberID = 114971560 AND AttributeGroupID = 122
SELECT * FROM LASQL05.mnmember17.dbo.MemberAttributeInt WHERE MemberID = 114971560 AND AttributeGroupID = 122

UPDATE mnmember17.dbo.MemberAttributeInt 
SET Value = 0
WHERE MemberID = 114971560 AND AttributeGroupID = 122

-- Fix any data issues
SELECT MemberID, AttributeGroupID, Value FROM LASQL05.mnMember17.dbo.MemberAttributeInt	 WHERE MemberID = 114971560
EXCEPT
SELECT MemberID, AttributeGroupID, Value FROM LASQL06.mnMember17.dbo.MemberAttributeInt	 WHERE MemberID = 114971560

SELECT MemberID, AttributeGroupID, Value FROM LASQL06.mnMember17.dbo.MemberAttributeInt	 WHERE MemberID = 114971560 
EXCEPT
SELECT MemberID, AttributeGroupID, Value FROM LASQL05.mnMember17.dbo.MemberAttributeInt	 WHERE MemberID = 114971560

SELECT rowid, MemberID, AttributeGroupID, Value FROM LASQL06.mnMember17.dbo.MemberAttributeInt	 WHERE MemberID = 114971560
EXCEPT
SELECT rowid, MemberID, AttributeGroupID, Value FROM LASQLPRODFLAT01.mnMember17.dbo.MemberAttributeInt	 WHERE MemberID = 114971560

SELECT rowid, MemberID, AttributeGroupID, Value FROM LASQLPRODFLAT01.mnMember17.dbo.MemberAttributeInt	 WHERE MemberID = 114971560
EXCEPT
SELECT rowid, MemberID, AttributeGroupID, Value FROM LASQL06.mnMember17.dbo.MemberAttributeInt	 WHERE MemberID = 114971560


UPDATE LASQLPRODFLAT01.mnMember17.dbo.MemberAttributeInt SET Value = 5881 WHERE MemberID = 114971560 AND AttributeGroupID = 640 AND Value != 5881
DELETE mnMember17.dbo.MemberAttributeInt WHERE MemberID = 114971560 AND ROWID = 46644235

BEGIN TRAN

SET IDENTITY_INSERT dbo.MemberAttributeInt ON

IF NOT EXISTS (SELECT * FROM mnMEmber17.dbo.MemberAttributeInt WITH (READUNCOMMITTED) WHERE rowid = 71734639 AND MemberID = 114971560)
	INSERT INTO mnMEmber17.dbo.MemberAttributeInt
			( rowid,MemberID, AttributeGroupID, Value )
	VALUES  ( 71734639,
			  114971560, -- MemberID - int
			  123, -- AttributeGroupID - int
			  1  -- Value - int
			  )

SET IDENTITY_INSERT dbo.MemberAttributeInt OFF


-- COMMIT
-- ROLLBACK