SELECT     
	'SELECT	' +
	'''CABIPV1\PROD1''	,	' + 
	'''' + ConfigurationFilter + ''',	' +
    '''' + ConfiguredValue + ''',	' +
    '''' + PackagePath + ''',	' +
    '''' + ConfiguredValueType + '''' +
    '	UNION ALL'
FROM SSIS.Configuration AS C WHERE ConfigurationFilter LIKE '%encomp%' ORDER BY ConfigurationFilter, PackagePath