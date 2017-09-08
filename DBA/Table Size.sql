/*
	Table Size
*/
SELECT 
    t.NAME AS TableName,
    i.name as indexName,
    sum(p.rows) as RowCounts,
    sum(a.total_pages) as TotalPages, 
    sum(a.used_pages) as UsedPages, 
    sum(a.data_pages) as DataPages,
    (sum(a.total_pages) * 8) / 1024 as TotalSpaceMB, 
    (sum(a.used_pages) * 8) / 1024 as UsedSpaceMB, 
    (sum(a.data_pages) * 8) / 1024 as DataSpaceMB
FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
WHERE 
    t.NAME NOT LIKE 'dt%' AND
    i.OBJECT_ID > 255 AND   
    i.index_id <= 1
GROUP BY 
    t.NAME, i.object_id, i.index_id, i.name 
ORDER BY 
    TotalSpaceMB DESC


-- find the table size info (no xml index) using sys.dm_db_partition_stats
-- Author: Jeffrey Yao
-- Date: Sept 27, 2010
select name=object_schema_name(object_id) + '.' + object_name(object_id)
, rows=sum(case when index_id < 2 then row_count else 0 end)
, reserved_kb=8*sum(reserved_page_count)
, data_kb=8*sum( case 
     when index_id<2 then in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count 
     else lob_used_page_count + row_overflow_used_page_count 
    end )
, index_kb=8*(sum(used_page_count) 
    - sum( case 
           when index_id<2 then in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count 
        else lob_used_page_count + row_overflow_used_page_count 
        end )
     )    
, unused_kb=8*sum(reserved_page_count-used_page_count)
from sys.dm_db_partition_stats
where object_id > 1024
group by object_id
order by 
--rows desc
 data_kb desc
-- reserved_kb desc
-- data_kb desc
-- index_kb desc
-- unsed_kb desc


/*
	Table size
*/
-- Script to analyze table space usage using the
-- output from the sp_spaceused stored procedure
-- Works with SQL 7.0, 2000, and 2005

set nocount on


print 'Show Size, Space Used, Unused Space, Type, and Name of all database files'

select
	[FileSizeMB]	=
		convert(numeric(10,2),sum(round(a.size/128.,2))),
        [UsedSpaceMB]	=
		convert(numeric(10,2),sum(round(fileproperty( a.name,'SpaceUsed')/128.,2))) ,
        [UnusedSpaceMB]	=
		convert(numeric(10,2),sum(round((a.size-fileproperty( a.name,'SpaceUsed'))/128.,2))) ,
	[Type] =
		case when a.groupid is null then '' when a.groupid = 0 then 'Log' else 'Data' end,
	[DBFileName]	= isnull(a.name,'*** Total for all files ***')
from
	sysfiles a
group by
	groupid,
	a.name
	with rollup
having
	a.groupid is null or
	a.name is not null
order by
	case when a.groupid is null then 99 when a.groupid = 0 then 0 else 1 end,
	a.groupid,
	case when a.name is null then 99 else 0 end,
	a.name



IF OBJECT_ID('tempdb..#TABLE_SPACE_WORK') IS NOT NULL
	DROP TABLE #TABLE_SPACE_WORK
create table #TABLE_SPACE_WORK
(
	TABLE_NAME 	sysname		not null ,
	TABLE_ROWS 	numeric(18,0)	not null ,
	RESERVED 	varchar(50) 	not null ,
	DATA 		varchar(50) 	not null ,
	INDEX_SIZE 	varchar(50) 	not null ,
	UNUSED 		varchar(50) 	not null ,
)

IF OBJECT_ID('tempdb..#TABLE_SPACE_USED') IS NOT NULL
	DROP TABLE #TABLE_SPACE_USED
create table #TABLE_SPACE_USED
(
	Seq		int		not null	
	identity(1,1)	primary key clustered,
	TABLE_NAME 	sysname		not null ,
	TABLE_ROWS 	numeric(18,0)	not null ,
	RESERVED 	varchar(50) 	not null ,
	DATA 		varchar(50) 	not null ,
	INDEX_SIZE 	varchar(50) 	not null ,
	UNUSED 		varchar(50) 	not null ,
)

IF OBJECT_ID('tempdb..#TABLE_SPACE') IS NOT NULL
	DROP TABLE #TABLE_SPACE
create table #TABLE_SPACE
(
	Seq		int		not null
	identity(1,1)	primary key clustered,
	TABLE_NAME 	SYSNAME 	not null ,
	TABLE_ROWS 	int	 	not null ,
	RESERVED 	int	 	not null ,
	DATA 		int	 	not null ,
	INDEX_SIZE 	int	 	not null ,
	UNUSED 		int	 	not null ,
	USED_MB				numeric(18,4)	not null,
	USED_GB				numeric(18,4)	not null,
	AVERAGE_BYTES_PER_ROW		numeric(18,5)	null,
	AVERAGE_DATA_BYTES_PER_ROW	numeric(18,5)	null,
	AVERAGE_INDEX_BYTES_PER_ROW	numeric(18,5)	null,
	AVERAGE_UNUSED_BYTES_PER_ROW	numeric(18,5)	null,
)

declare @fetch_status int

declare @proc 	varchar(200)
select	@proc	= 'dbo.sp_spaceused'

declare Cur_Cursor cursor local
for
select
	TABLE_NAME	= 
	rtrim(TABLE_SCHEMA)+'.'+rtrim(TABLE_NAME)
from
	INFORMATION_SCHEMA.TABLES 
where
	TABLE_TYPE	= 'BASE TABLE'
AND TABLE_NAME NOT LIKE '%.%'
order by
	1

open Cur_Cursor

declare @TABLE_NAME 	varchar(200)

select @fetch_status = 0

while @fetch_status = 0
	begin

	fetch next from Cur_Cursor
	into
		@TABLE_NAME

	select @fetch_status = @@fetch_status

	if @fetch_status <> 0
		begin
		continue
		end

	truncate table #TABLE_SPACE_WORK

	insert into #TABLE_SPACE_WORK
		(
		TABLE_NAME,
		TABLE_ROWS,
		RESERVED,
		DATA,
		INDEX_SIZE,
		UNUSED
		)
	exec @proc @objname = 
		@TABLE_NAME ,@updateusage = 'true'


	-- Needed to work with SQL 7
	update #TABLE_SPACE_WORK
	set
		TABLE_NAME = @TABLE_NAME

	insert into #TABLE_SPACE_USED
		(
		TABLE_NAME,
		TABLE_ROWS,
		RESERVED,
		DATA,
		INDEX_SIZE,
		UNUSED
		)
	select
		TABLE_NAME,
		TABLE_ROWS,
		RESERVED,
		DATA,
		INDEX_SIZE,
		UNUSED
	from
		#TABLE_SPACE_WORK

	end 	--While end

close Cur_Cursor

deallocate Cur_Cursor

insert into #TABLE_SPACE
	(
	TABLE_NAME,
	TABLE_ROWS,
	RESERVED,
	DATA,
	INDEX_SIZE,
	UNUSED,
	USED_MB,
	USED_GB,
	AVERAGE_BYTES_PER_ROW,
	AVERAGE_DATA_BYTES_PER_ROW,
	AVERAGE_INDEX_BYTES_PER_ROW,
	AVERAGE_UNUSED_BYTES_PER_ROW

	)
select
	TABLE_NAME,
	TABLE_ROWS,
	RESERVED,
	DATA,
	INDEX_SIZE,
	UNUSED,
	USED_MB			=
		round(convert(numeric(25,10),RESERVED)/
		convert(numeric(25,10),1024),4),
	USED_GB			=
		round(convert(numeric(25,10),RESERVED)/
		convert(numeric(25,10),1024*1024),4),
	AVERAGE_BYTES_PER_ROW	=
		case
		when TABLE_ROWS <> 0
		then round(
		(1024.000000*convert(numeric(25,10),RESERVED))/
		convert(numeric(25,10),TABLE_ROWS),5)
		else null
		end,
	AVERAGE_DATA_BYTES_PER_ROW	=
		case
		when TABLE_ROWS <> 0
		then round(
		(1024.000000*convert(numeric(25,10),DATA))/
		convert(numeric(25,10),TABLE_ROWS),5)
		else null
		end,
	AVERAGE_INDEX_BYTES_PER_ROW	=
		case
		when TABLE_ROWS <> 0
		then round(
		(1024.000000*convert(numeric(25,10),INDEX_SIZE))/
		convert(numeric(25,10),TABLE_ROWS),5)
		else null
		end,
	AVERAGE_UNUSED_BYTES_PER_ROW	=
		case
		when TABLE_ROWS <> 0
		then round(
		(1024.000000*convert(numeric(25,10),UNUSED))/
		convert(numeric(25,10),TABLE_ROWS),5)
		else null
		end
from
	(
	select
		TABLE_NAME,
		TABLE_ROWS,
		RESERVED	= 
		convert(int,rtrim(replace(RESERVED,'KB',''))),
		DATA		= 
		convert(int,rtrim(replace(DATA,'KB',''))),
		INDEX_SIZE	= 
		convert(int,rtrim(replace(INDEX_SIZE,'KB',''))),
		UNUSED		= 
		convert(int,rtrim(replace(UNUSED,'KB','')))
	from
		#TABLE_SPACE_USED aa
	) a
order by
	TABLE_NAME

print 'Show results in descending order by size in MB'

select * from #TABLE_SPACE order by USED_MB desc
go


