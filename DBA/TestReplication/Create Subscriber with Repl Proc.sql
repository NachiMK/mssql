USE [master]
GO
/****** Object:  Database [TestRepl]    Script Date: 11/3/2015 9:31:42 AM ******/
CREATE DATABASE [TestRepl] ON  PRIMARY 
( NAME = N'TestRepl', FILENAME = N'E:\SQL_DATA\TestRepl.mdf' , SIZE = 32768KB , MAXSIZE = 2GB, FILEGROWTH = 10% )
 LOG ON 
( NAME = N'TestRepl_log', FILENAME = N'E:\SQL_LOG\TestRepl_log.ldf' , SIZE = 16384KB , MAXSIZE = 2GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [TestRepl] SET COMPATIBILITY_LEVEL = 100
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [TestRepl].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [TestRepl] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [TestRepl] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [TestRepl] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [TestRepl] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [TestRepl] SET ARITHABORT OFF 
GO
ALTER DATABASE [TestRepl] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [TestRepl] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [TestRepl] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [TestRepl] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [TestRepl] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [TestRepl] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [TestRepl] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [TestRepl] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [TestRepl] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [TestRepl] SET  DISABLE_BROKER 
GO
ALTER DATABASE [TestRepl] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [TestRepl] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [TestRepl] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [TestRepl] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [TestRepl] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [TestRepl] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [TestRepl] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [TestRepl] SET RECOVERY FULL 
GO
ALTER DATABASE [TestRepl] SET  MULTI_USER 
GO
ALTER DATABASE [TestRepl] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [TestRepl] SET DB_CHAINING OFF 
GO
USE [TestRepl]
GO
/****** Object:  User [MATCHNET\SQLDBO]    Script Date: 11/3/2015 9:31:42 AM ******/
CREATE USER [MATCHNET\SQLDBO] FOR LOGIN [MATCHNET\SQLDBO]
GO
ALTER ROLE [db_datareader] ADD MEMBER [MATCHNET\SQLDBO]
GO
/****** Object:  Table [dbo].[ProdFlat]    Script Date: 11/3/2015 9:31:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProdFlat](
	[ProdFlatId] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[IntValue] [bigint] NOT NULL,
	[DateValue] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_ProdFlat_1] PRIMARY KEY CLUSTERED 
(
	[ProdFlatId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  StoredProcedure [dbo].[sp_MSins_dboProdFlat]    Script Date: 11/3/2015 9:31:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSins_dboProdFlat]
    @c1 int,
    @c2 bigint,
    @c3 datetimeoffset
as
begin  
	insert into [dbo].[ProdFlat](
		[ProdFlatId],
		[IntValue],
		[DateValue]
	) values (
    @c1,
    @c2,
    @c3	) 
end  

GO
/****** Object:  StoredProcedure [dbo].[sp_MSupd_dboProdFlat]    Script Date: 11/3/2015 9:31:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[sp_MSupd_dboProdFlat]
		@c1 int = NULL,
		@c2 bigint = NULL,
		@c3 datetimeoffset = NULL,
		@pkc1 int = NULL,
		@bitmap binary(1)
as
begin  
update [dbo].[ProdFlat] set
		[IntValue] = case substring(@bitmap,1,1) & 2 when 2 then @c2 else [IntValue] end,
		[DateValue] = case substring(@bitmap,1,1) & 4 when 4 then @c3 else [DateValue] end
where [ProdFlatId] = @pkc1
if @@rowcount = 0
    if @@microsoftversion>0x07320000
        exec sp_MSreplraiserror 20598
end 

GO
/****** Object:  DdlTrigger [LogEvents]    Script Date: 11/3/2015 9:31:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

      CREATE TRIGGER [LogEvents]
      ON DATABASE
      AFTER DDL_DATABASE_LEVEL_EVENTS
      AS
      IF charindex('Create_Statistics',CONVERT(VARCHAR(MAX),eventdata()),1) = 0 and charindex('Update_Statistics',CONVERT(VARCHAR(MAX),eventdata()),1) = 0 and charindex('MATCHNET\confluencedbuser',CONVERT(VARCHAR(MAX),eventdata()),1) = 0  and charindex('MATCHNET\jiradbuser',CONVERT(VARCHAR(MAX),eventdata()),1) = 0
            INSERT INTO mndba.dbo.DDLDatabaseLog (EventInstance)
            VALUES (EVENTDATA())
GO
ENABLE TRIGGER [LogEvents] ON DATABASE
GO
USE [master]
GO
ALTER DATABASE [TestRepl] SET  READ_WRITE 
GO
