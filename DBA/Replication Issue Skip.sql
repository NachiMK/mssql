/*
{CALL [sp_MSdel_dboMemberAttributeInt] (4314827,8082772)}
{CALL [sp_MSins_dboMemberAttributeInt] (4314827,8082772,122,0)}
{CALL [sp_MSdel_dboMemberAttributeInt] (67715331,8082772)}
*/
/*
{CALL [sp_MSdel_dboMemberAttributeInt] (4314827,8082772)}
{CALL [sp_MSins_dboMemberAttributeInt] (4314827,8082772,122,0)}
{CALL [sp_MSdel_dboMemberAttributeInt] (67805077,8082772)}
*/
-- 0x000043880003DA54000100000000
USE mnmember5
GO
EXEC sp_setsubscriptionxactseqno  @publisher =  'LASQL02' 
        ,  @publisher_db =  'mnMember5' 
        ,  @publication =  'mnMember5 LASQLPRODFLAT01 Replication' 
        ,  @xact_seqno =  0x000043880003DA54000100000000

SELECT * FROM mnmember5.dbo.MemberAttributeInt WHERE MemberID = 8082772 AND rowid IN (4314827, 67805077)
SELECT * FROM LASQL01.mnmember5.dbo.MemberAttributeInt WHERE MemberID = 8082772 AND rowid IN (4314827, 67805077)
SELECT * FROM LASQL02.mnmember5.dbo.MemberAttributeInt WHERE MemberID = 8082772 AND rowid IN (4314827, 67805077)

SELECT * FROM mnmember5.dbo.MemberAttributeInt WHERE MemberID = 8082772 AND AttributeGroupID = 122
SELECT * FROM LASQL01.mnmember5.dbo.MemberAttributeInt WHERE MemberID = 8082772 AND AttributeGroupID = 122
SELECT * FROM LASQL02.mnmember5.dbo.MemberAttributeInt WHERE MemberID = 8082772 AND AttributeGroupID = 122

--0x000043880001A8BC000100000000


USE mnmember5
GO
/*
{CALL [sp_MSdel_dboMemberAttributeInt] (4314827,8082772)}
{CALL [sp_MSins_dboMemberAttributeInt] (4314827,8082772,122,0)}
{CALL [sp_MSdel_dboMemberAttributeInt] (67803888,8082772)}
*/
EXEC sp_setsubscriptionxactseqno  @publisher =  'LASQL02' 
        ,  @publisher_db =  'mnMember5' 
        ,  @publication =  'mnMember5 LASQLPRODFLAT01 Replication' 
        ,  @xact_seqno =  0x000043880001A8BC000100000000
SELECT * FROM mnmember5.dbo.MemberAttributeInt WHERE MemberID = 8082772 AND rowid IN (4314827, 67715331)
SELECT * FROM LASQL01.mnmember5.dbo.MemberAttributeInt WHERE MemberID = 8082772 AND rowid IN (4314827, 67715331)
SELECT * FROM LASQL02.mnmember5.dbo.MemberAttributeInt WHERE MemberID = 8082772 AND rowid IN (4314827, 67715331)

SELECT * FROM mnmember5.dbo.MemberAttributeInt WHERE MemberID = 8082772 AND AttributeGroupID = 122
SELECT * FROM LASQL01.mnmember5.dbo.MemberAttributeInt WHERE MemberID = 8082772 AND AttributeGroupID = 122
SELECT * FROM LASQL02.mnmember5.dbo.MemberAttributeInt WHERE MemberID = 8082772 AND AttributeGroupID = 122

--0x0000389000015631000100000000
/*
{CALL [sp_MSdel_dboMemberAttributeInt] (70096243,120283751)}
{CALL [sp_MSdel_dboMemberAttributeInt] (70106573,120283751)}
*/
-- 0x0000389000015631000100000000
USE mnmember24
GO
EXEC sp_setsubscriptionxactseqno  @publisher =  'LASQL08' 
        ,  @publisher_db =  'mnMember24' 
        ,  @publication =  'mnMember24 LASQLPRODFLAT01 Replication' 
        ,  @xact_seqno =  0x0000389200026E97000100000000

SELECT * FROM mnmember5.dbo.MemberAttributeInt WHERE MemberID = 8082772 AND rowid IN (4314827, 67715331)
SELECT * FROM LASQL01.mnmember5.dbo.MemberAttributeInt WHERE MemberID = 8082772 AND rowid IN (4314827, 67715331)
SELECT * FROM LASQL02.mnmember5.dbo.MemberAttributeInt WHERE MemberID = 8082772 AND rowid IN (4314827, 67715331)

SELECT * FROM mnmember24.dbo.MemberAttributeInt WHERE MemberID = 120283751 AND rowid IN (70096243)
SELECT * FROM LASQL07.mnmember24.dbo.MemberAttributeInt WHERE MemberID = 120283751  AND rowid IN (70096243)
SELECT * FROM LASQL08.mnmember24.dbo.MemberAttributeInt WHERE MemberID = 120283751 AND rowid IN (70096243)