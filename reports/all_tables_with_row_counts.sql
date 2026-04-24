-- found: https://stackoverflow.com/a/2611745

WITH tbl AS (
  SELECT
    table_schema,
    table_name
  FROM information_schema.tables
  WHERE
    table_name NOT LIKE 'pg_%'
    AND table_schema IN ('public')
    AND table_type = 'BASE TABLE'
)

SELECT
  table_name,
  (xpath('/row/c/text()', query_to_xml(format(
    'SELECT count(*) AS c FROM %I.%I', table_schema, table_name
  ), FALSE, TRUE, '')))[1]::text::int AS records_count
FROM tbl
ORDER BY records_count DESC;
