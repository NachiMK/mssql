USE [mnDBA]
GO

/****** Object:  Schema [perf]    Script Date: 1/19/2017 8:38:10 AM ******/
CREATE SCHEMA [perf]
GO

USE [mnDBA]
GO

/****** Object:  Table [dbo].[DisableOrEnableJobLog]    Script Date: 1/19/2017 8:36:10 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DisableOrEnableJobLog](
	[JobEnableDisableLogId] [INT] IDENTITY(1,1) NOT NULL,
	[Reason] [sysname] NOT NULL,
	[ServerName] [sysname] NOT NULL,
	[job_id] [UNIQUEIDENTIFIER] NOT NULL,
	[PrevEnabled] [BIT] NOT NULL,
	[jobName] [sysname] NOT NULL,
	[category_id] [INT] NOT NULL,
	[category] [sysname] NOT NULL,
	[DisabledTime] [DATETIME] NULL,
	[EnabledBy] [sysname] NULL,
	[EnableTime] [DATETIME] NULL,
	[CreatedDtTm] [DATETIME] NOT NULL CONSTRAINT [DF_DisableOrEnableJobLog_CreatedtTm]  DEFAULT (GETDATE()),
	[CreatedBy] [sysname] NOT NULL
) ON [PRIMARY]

GO



USE [mnDBA]
GO

/****** Object:  Table [dbo].[DBGrowthRate]    Script Date: 1/19/2017 8:36:01 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[DBGrowthRate](
	[DBGrowthID] [INT] IDENTITY(1,1) NOT NULL,
	[DBName] [VARCHAR](100) NULL,
	[DBID] [INT] NULL,
	[NumPages] [INT] NULL,
	[OrigSize] [DECIMAL](18, 2) NULL,
	[CurSize] [DECIMAL](18, 2) NULL,
	[GrowthAmt] [VARCHAR](100) NULL,
	[MetricDate] [DATETIME] NULL,
	[DataSize] [INT] NULL,
	[LogSize] [INT] NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO



USE [mnDBA]
GO

/****** Object:  Table [dbo].[_NM_JobDisableLog]    Script Date: 1/19/2017 8:35:46 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[_NM_JobDisableLog](
	[JobEnableDisableLogId] [INT] IDENTITY(1,1) NOT NULL,
	[BatchName] [sysname] NOT NULL,
	[ServerName] [sysname] NOT NULL,
	[job_id] [UNIQUEIDENTIFIER] NOT NULL,
	[PrevEnabled] [BIT] NOT NULL,
	[jobName] [sysname] NOT NULL,
	[category_id] [INT] NOT NULL,
	[category] [sysname] NOT NULL,
	[DisabledTime] [DATETIME] NULL,
	[EnableTime] [DATETIME] NULL,
	[CreatedDtTm] [DATETIME] NOT NULL CONSTRAINT [DF_JobDisableEnableLog_CreatedtTm]  DEFAULT (GETDATE())
) ON [PRIMARY]

GO



USE [mnDBA]
GO

/****** Object:  Table [dbo].[DDLServerLog]    Script Date: 1/19/2017 8:35:27 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[DDLServerLog](
	[RowNum] [INT] IDENTITY(1,1) NOT NULL,
	[EventType] [NVARCHAR](100) NULL,
	[AttemptedDate] [DATETIME] NOT NULL,
	[ServerLogin] [NVARCHAR](100) NOT NULL,
	[DBUser] [NVARCHAR](100) NOT NULL,
	[TSQLText] [VARCHAR](MAX) NULL,
	[EventData] [XML] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO



USE [mnDBA]
GO

/****** Object:  Table [dbo].[DDLDatabaseLog]    Script Date: 1/19/2017 8:35:22 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DDLDatabaseLog](
	[EventID] [INT] IDENTITY(1,1) NOT NULL,
	[EventInstance] [XML] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO


USE [mnDBA]
GO

/****** Object:  Table [perf].[WaitStats]    Script Date: 1/19/2017 8:35:06 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [perf].[WaitStats](
	[ID] [INT] IDENTITY(1,1) NOT NULL,
	[ServerName] [NVARCHAR](128) NULL,
	[CheckDate] [DATETIMEOFFSET](7) NULL,
	[wait_type] [NVARCHAR](60) NULL,
	[wait_time_ms] [BIGINT] NULL,
	[signal_wait_time_ms] [BIGINT] NULL,
	[waiting_tasks_count] [BIGINT] NULL,
 CONSTRAINT [PK_B7864B5C-B70D-4E05-908A-0FA9C45C6C70] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


USE [mnDBA]
GO

/****** Object:  Table [perf].[ServerStats]    Script Date: 1/19/2017 8:35:00 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [perf].[ServerStats](
	[ID] [INT] IDENTITY(1,1) NOT NULL,
	[ServerName] [NVARCHAR](128) NULL,
	[CheckDate] [DATETIMEOFFSET](7) NULL,
	[CheckID] [INT] NOT NULL,
	[Priority] [TINYINT] NOT NULL,
	[FindingsGroup] [VARCHAR](50) NOT NULL,
	[Finding] [VARCHAR](200) NOT NULL,
	[URL] [VARCHAR](200) NOT NULL,
	[Details] [NVARCHAR](4000) NULL,
	[HowToStopIt] [XML] NULL,
	[QueryPlan] [XML] NULL,
	[QueryText] [NVARCHAR](MAX) NULL,
	[StartTime] [DATETIMEOFFSET](7) NULL,
	[LoginName] [NVARCHAR](128) NULL,
	[NTUserName] [NVARCHAR](128) NULL,
	[OriginalLoginName] [NVARCHAR](128) NULL,
	[ProgramName] [NVARCHAR](128) NULL,
	[HostName] [NVARCHAR](128) NULL,
	[DatabaseID] [INT] NULL,
	[DatabaseName] [NVARCHAR](128) NULL,
	[OpenTransactionCount] [INT] NULL,
	[DetailsInt] [INT] NULL,
 CONSTRAINT [PK_398041C6-778F-4CFC-8E0C-0411C238E45D] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


USE [mnDBA]
GO

/****** Object:  Table [perf].[PerfmonStats]    Script Date: 1/19/2017 8:34:55 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [perf].[PerfmonStats](
	[ID] [INT] IDENTITY(1,1) NOT NULL,
	[ServerName] [NVARCHAR](128) NULL,
	[CheckDate] [DATETIMEOFFSET](7) NULL,
	[object_name] [NVARCHAR](128) NOT NULL,
	[counter_name] [NVARCHAR](128) NOT NULL,
	[instance_name] [NVARCHAR](128) NULL,
	[cntr_value] [BIGINT] NULL,
	[cntr_type] [INT] NOT NULL,
	[value_delta] [BIGINT] NULL,
	[value_per_second] [DECIMAL](18, 2) NULL,
 CONSTRAINT [PK_69F322BD-AB13-4C61-9CAD-D02993F07B92] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


USE [mnDBA]
GO

/****** Object:  Table [perf].[FileStats]    Script Date: 1/19/2017 8:34:46 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [perf].[FileStats](
	[ID] [INT] IDENTITY(1,1) NOT NULL,
	[ServerName] [NVARCHAR](128) NULL,
	[CheckDate] [DATETIMEOFFSET](7) NULL,
	[DatabaseID] [INT] NOT NULL,
	[FileID] [INT] NOT NULL,
	[DatabaseName] [NVARCHAR](256) NULL,
	[FileLogicalName] [NVARCHAR](256) NULL,
	[TypeDesc] [NVARCHAR](60) NULL,
	[SizeOnDiskMB] [BIGINT] NULL,
	[io_stall_read_ms] [BIGINT] NULL,
	[num_of_reads] [BIGINT] NULL,
	[bytes_read] [BIGINT] NULL,
	[io_stall_write_ms] [BIGINT] NULL,
	[num_of_writes] [BIGINT] NULL,
	[bytes_written] [BIGINT] NULL,
	[PhysicalName] [NVARCHAR](520) NULL,
 CONSTRAINT [PK_477392E4-F3CD-417C-8F16-B5268CD3BA66] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


USE [mnDBA]
GO

/****** Object:  Table [dbo].[TableSizeAudit]    Script Date: 1/19/2017 8:34:42 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[TableSizeAudit](
	[databasename] [VARCHAR](256) NULL,
	[tablename] [VARCHAR](256) NULL,
	[rows] [INT] NULL,
	[reserved] [VARCHAR](90) NULL,
	[data] [VARCHAR](90) NULL,
	[indexsize] [VARCHAR](90) NULL,
	[unused] [VARCHAR](90) NULL,
	[insertdate] [DATETIME] NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


