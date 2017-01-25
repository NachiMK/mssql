DECLARE @XMLAsString VARCHAR(MAX)	=	'<?xml version="1.0" encoding="UTF-8"?>
<opens type="array">
    <open>
        <account-id>487</account-id>
        <campaign-id>351732</campaign-id>
        <contact-id>516041869</contact-id>
        <browser>Other</browser>
        <recorded-at>2016-01-31T19:00:02-05:00</recorded-at>
        <id >516041869</id>
        <email>houseonly@comcast.net</email>
        <memberid>146565206</memberid>
    </open>
    <open>
        <account-id>487</account-id>
        <campaign-id type="integer">504076</campaign-id>
        <contact-id type="integer">408292362</contact-id>
        <browser>Other</browser>
        <recorded-at type="dateTime">2016-01-31T19:06:24-05:00</recorded-at>
        <id type="integer">408292362</id>
        <email>lulurose231@gmail.com</email>
        <memberid>146921704</memberid>
    </open>
    <open>
        <account-id>487</account-id>
        <campaign-id type="integer">504076</campaign-id>
        <contact-id type="integer">396046029</contact-id>
        <browser>Other</browser>
        <recorded-at type="dateTime">2016-01-31T19:06:29-05:00</recorded-at>
        <id type="integer">396046029</id>
        <email>mafreed916@yahoo.com</email>
        <memberid>150336961</memberid>
    </open>
    <open>
        <account-id>487</account-id>
        <campaign-id type="integer">477920</campaign-id>
        <contact-id type="integer">574276420</contact-id>
        <browser>Other</browser>
        <recorded-at type="dateTime">2016-01-31T19:06:29-05:00</recorded-at>
        <id type="integer">574276420</id>
        <email>justindeloy@gmail.com</email>
        <memberid>146654999</memberid>
    </open>
</opens>'

DECLARE @XML XML = @XMLAsString

SELECT @XML

SELECT	 AccountID		= T.value('(account-id)[1]', 'bigint')
		,CampaignId		= T.value('(campaign-id)[1]', 'bigint')
		,ContactId		= T.value('(contact-id)[1]', 'bigint')
		,Browser		= T.value('(browser)[1]', 'varchar(500)')
		,RecordedAt		= T.value('(recorded-at)[1]', 'DATETIMEOFFSET')
		,Email			= T.value('(email)[1]', 'varchar(200)')
		,MemberId		= T.value('(memberid)[1]', 'int')
FROM	@XML.nodes('/opens/open') AS MaropostOpen(T)





;WITH	Xml_CTE
		  AS (SELECT	CAST('/' + node.value('fn:local-name(.)',
											  'varchar(100)') AS VARCHAR(100)) AS name
					   ,node.query('*') AS children
			  FROM		@xml.nodes('/*') AS roots (node)
			  UNION ALL
			  SELECT	CAST(x.name + '/' + node.value('fn:local-name(.)',
													   'varchar(100)') AS VARCHAR(100))
					   ,node.query('*') AS children
			  FROM		Xml_CTE x
			  CROSS APPLY x.children.nodes('*') AS child (node)
			 )
	SELECT DISTINCT
			name
	FROM	Xml_CTE
OPTION	(MAXRECURSION 2)

declare @SQL nvarchar(max) = ''
declare @Col nvarchar(max) = ', T.N.value(''([COLNAME])[1]'', ''varchar(100)'') as [[COLNAME]]' 

select @SQL = @SQL + replace(@Col, '[COLNAME]', T.N.value('local-name(.)', 'sysname'))
from @XML.nodes('/opens/open[1]/*') as T(N)

set @SQL = 'select '+stuff(@SQL, 1, 2, '')+' from @XML.nodes(''/opens/open'') as T(N)' 

PRINT @SQL

select T.N.value('(account-id)[1]', 'varchar(100)') as [account-id], T.N.value('(campaign-id)[1]', 'varchar(100)') as [campaign-id], T.N.value('(contact-id)[1]', 'varchar(100)') as [contact-id], T.N.value('(browser)[1]', 'varchar(100)') as [browser], T.N.value('(recorded-at)[1]', 'varchar(100)') as [recorded-at], T.N.value('(id)[1]', 'varchar(100)') as [id], T.N.value('(email)[1]', 'varchar(100)') as [email], T.N.value('(memberid)[1]', 'varchar(100)') as [memberid] from @XML.nodes('/opens/open') as T(N)
