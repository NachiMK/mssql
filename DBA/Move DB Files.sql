USE master;
GO

-- Return the logical file name.
SELECT name, physical_name AS CurrentLocation, state_desc
FROM sys.master_files
WHERE database_id = DB_ID(N'Maropost')
--    AND type_desc = N'LOG';
GO

ALTER DATABASE Maropost SET OFFLINE;
GO
-- Physically move the file to a new location.

-- MOVE MDF File
ALTER DATABASE Maropost 
    MODIFY FILE ( NAME = Maropost, 
                  FILENAME = 'D:\SQL_DATA\Maropost.mdf');
GO

-- MOVE LDF File
ALTER DATABASE Maropost 
    MODIFY FILE ( NAME = Maropost_Log, 
                  FILENAME = 'D:\SQL_LOG\Maropost_Log.ldf');
GO
ALTER DATABASE Maropost SET ONLINE;
GO
--Verify the new location.
SELECT name, physical_name AS CurrentLocation, state_desc
FROM sys.master_files
WHERE database_id = DB_ID(N'Maropost')
--    AND type_desc = N'LOG';
