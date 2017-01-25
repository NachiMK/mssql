-- 4-webinar_missing_comp.sql
SELECT n.nspname AS schemaname, 
	c.relname AS tablename, 
	a.attname AS "column", 
	format_type(a.atttypid, a.atttypmod) AS "type", 
	format_encoding(a.attencodingtype::integer) AS "encoding"
FROM pg_namespace n, pg_class c, pg_attribute a
WHERE n.oid = c.relnamespace 
	AND c.oid = a.attrelid 
	AND a.attnum > 0 
	AND c.relkind = 'r' 
	AND NOT a.attisdropped 
	AND n.nspname NOT IN ('information_schema','pg_catalog','pg_toast') 
	AND format_encoding(a.attencodingtype::integer) = 'none'
	AND a.attsortkeyord <> 1 
  ORDER BY n.nspname, c.relname, a.attnum;