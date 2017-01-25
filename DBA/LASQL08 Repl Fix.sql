--{CALL [sp_MSdel_dboMemberAttributeInt] (70688113,120283751)}
--{CALL [sp_MSdel_dboMemberAttributeInt] (70819499,120283751)}
-- {CALL [sp_MSdel_dboMemberAttributeInt] (70968965,120283751)}
-- {CALL [sp_MSdel_dboMemberAttributeInt] (70984549,120283751)}
-- {CALL [sp_MSdel_dboMemberAttributeInt] (71006213,120283751)}
USE mnmember24
GO
EXEC sp_setsubscriptionxactseqno  @publisher =  'LASQL08' 
        ,  @publisher_db =  'mnMember24' 
        ,  @publication =  'mnMember24 LASQLPRODFLAT01 Replication' 
        ,  @xact_seqno =  0x0000398C0001F95A000100000000

SELECT * FROM mnmember24.dbo.MemberAttributeInt WHERE MemberID = 120283751 AND rowid IN (70641962, 65837834)
SELECT * FROM LASQL08.mnmember24.dbo.MemberAttributeInt WHERE MemberID = 120283751 AND rowid IN (70641962, 65837834)
SELECT * FROM LASQL07.mnmember24.dbo.MemberAttributeInt WHERE MemberID = 120283751 AND rowid IN (70641962, 65837834)

SELECT * FROM mnmember14.dbo.MemberAttributeInt WHERE MemberID = 120283751 --AND AttributeGroupID = 122
SELECT * FROM LASQL06.mnmember14.dbo.MemberAttributeInt WHERE MemberID = 120283751 --AND AttributeGroupID = 122
SELECT * FROM LASQL05.mnmember14.dbo.MemberAttributeInt WHERE MemberID = 120283751 --AND AttributeGroupID = 122


-- {CALL [sp_MSdel_dboMemberAttributeInt] (69247479,142680477)}
-- 0x000034AF0000CAFA000100000000
--{CALL [sp_MSdel_dboMemberAttributeInt] (70400633,142680477)}
--{CALL [sp_MSdel_dboMemberAttributeInt] (70400633,142680477)}
--{CALL [sp_MSdel_dboMemberAttributeInt] (70948879,142680477)}
--{CALL [sp_MSdel_dboMemberAttributeInt] (71501106,142680477)}
USE mnMember22
GO
EXEC sp_setsubscriptionxactseqno  @publisher =  'LASQL08' 
        ,  @publisher_db =  'mnMember22' 
        ,  @publication =  'mnMember22 LASQLPRODFLAT01 Replication' 
        ,  @xact_seqno =  0x0000385C0000E95F000100000000

SELECT * FROM mnmember22.dbo.MemberAttributeInt WHERE MemberID = 142680477 AND AttributeGroupID = 5065
SELECT * FROM LASQL08.mnmember22.dbo.MemberAttributeInt WHERE MemberID = 142680477 AND AttributeGroupID = 5065 --AND rowid IN (71501106)
SELECT * FROM LASQL07.mnmember22.dbo.MemberAttributeInt WHERE MemberID = 142680477 AND AttributeGroupID = 5065 --AND rowid IN (71501106)

-- Fix any data issues
SELECT MemberID, AttributeGroupID, Value FROM LASQL07.mnMember22.dbo.MemberAttributeInt	 WHERE MemberID = 142680477 
EXCEPT
SELECT MemberID, AttributeGroupID, Value FROM LASQL08.mnMember22.dbo.MemberAttributeInt	 WHERE MemberID = 142680477

SELECT MemberID, AttributeGroupID, Value FROM LASQL08.mnMember22.dbo.MemberAttributeInt	 WHERE MemberID = 142680477 
EXCEPT
SELECT MemberID, AttributeGroupID, Value FROM LASQL07.mnMember22.dbo.MemberAttributeInt	 WHERE MemberID = 142680477

SELECT rowid, MemberID, AttributeGroupID, Value FROM LASQL08.mnMember22.dbo.MemberAttributeInt	 WHERE MemberID = 142680477
EXCEPT
SELECT rowid, MemberID, AttributeGroupID, Value FROM LASQLPRODFLAT01.mnMember22.dbo.MemberAttributeInt	 WHERE MemberID = 142680477

SELECT rowid, MemberID, AttributeGroupID, Value FROM LASQLPRODFLAT01.mnMember22.dbo.MemberAttributeInt	 WHERE MemberID = 142680477
EXCEPT
SELECT rowid, MemberID, AttributeGroupID, Value FROM LASQL08.mnMember22.dbo.MemberAttributeInt	 WHERE MemberID = 142680477

IF EXISTS (SELECT * FROM mnMember22.dbo.MemberAttributeInt WHERE MemberID = 142680477 AND rowid = 45596833)
	DELETE mnMember22.dbo.MemberAttributeInt WHERE MemberID = 142680477 AND rowid = 45596833

/*
{CALL [sp_MSdel_dboMemberAttributeInt] (36072115,114971560)}
{CALL [sp_MSins_dboMemberAttributeInt] (36072115,114971560,122,0)}
{CALL [sp_MSdel_dboMemberAttributeInt] (70408984,114971560)}
*/
USE mnmember17
GO
EXEC sp_setsubscriptionxactseqno  @publisher =  'LASQL06' 
        ,  @publisher_db =  'mnMember17' 
        ,  @publication =  'mnMember17 LASQLPRODFLAT01 Replication' 
        ,  @xact_seqno =  0x00003AB300034819000100000000
SELECT * FROM mnmember17.dbo.MemberAttributeInt WHERE MemberID = 114971560 AND AttributeGroupID = 122
SELECT * FROM LASQL05.mnmember17.dbo.MemberAttributeInt WHERE MemberID = 114971560 AND AttributeGroupID = 122
SELECT * FROM LASQL06.mnmember17.dbo.MemberAttributeInt WHERE MemberID = 114971560 AND AttributeGroupID = 122

USE mnmember23
GO

EXEC sp_setsubscriptionxactseqno  @publisher =  'LASQL08' 
        ,  @publisher_db =  'mnMember23' 
        ,  @publication =  'mnMember23 LASQLPRODFLAT01 Replication' 
        ,  @xact_seqno =  0x00003CC500026981000100000000


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
