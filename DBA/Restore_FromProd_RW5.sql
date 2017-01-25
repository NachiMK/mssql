-- RESTORE FILELISTONLY FROM DISK = '\\asm.lan\dcshare\Backup\NV\SQL\Dev\BI\NVBIDBD1\RW5_NB_092214.BAK' WITH FILE = 1

-- RESTORE RW5 FROM PROD
RESTORE DATABASE RW5
FROM DISK = N'\\asm.lan\dcshare\Backup\NV\SQL\Dev\BI\NVBIDBD1\RW5_NB_092214.BAK' 
WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 10,
MOVE 'RW5_Data'		TO 'E:\Data\RW5_1_Data.mdf',
MOVE 'RW5_Text'		TO 'E:\Data\RW5_2_Text.ndf',
MOVE 'RW5_Img'		TO 'E:\Data\RW_3_Img.ndf',
MOVE 'RW5_Idx'		TO 'E:\Data\RW5_4_Idx.ndf',
MOVE 'RW5_Indexes'	TO 'E:\Data\RW5_5_Indexes.ndf',
MOVE 'DistanceFG'	TO 'E:\Data\RW5_6_DistanceFG.ndf',
MOVE 'RW5_Log'		TO 'E:\Log\RW5_7_Log.ldf'
