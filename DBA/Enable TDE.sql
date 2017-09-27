/*
	Sample script to enable TDE, 
	1. Create Master key 
	2. Create Certifcate
	3. Enable encryption on a database
	4. backup encryption cert
*/
USE MASTER  
GO  
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'TypeYourCrazyP@ssW0rd' 
GO

CREATE CERTIFICATE TDECert 
WITH SUBJECT = 'My TDE Certificate for all user database'

USE [Amazon]  
GO  
CREATE DATABASE ENCRYPTION KEY  
WITH ALGORITHM = AES_128  
ENCRYPTION BY SERVER CERTIFICATE TDECert 
GO

ALTER DATABASE [Amazon] 
SET ENCRYPTION ON

USE MASTER  
GO  
BACKUP CERTIFICATE TDECert   
TO FILE = 'C:\SQL\SQL_CERT\Nachi_Localhost_TDECert_File.cer'  
WITH PRIVATE KEY (FILE = 'C:\SQL\SQL_CERT\Nachi_Localhost_TDECert_Key.pvk' ,  
ENCRYPTION BY PASSWORD = 'TypeYourCrazyP@ssW0rd' )  
GO


