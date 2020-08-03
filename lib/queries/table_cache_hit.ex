defmodule EctoPSQLExtras.TableCacheHit do
  def title do
    "Calculates your cache hit rate for reading tables"
  end

  def query do
"""
/* Calculates your cache hit rate for reading tables */

SELECT
  relname AS name,
  heap_blks_hit AS buffer_hits,
  heap_blks_read AS block_reads,
  heap_blks_hit + heap_blks_read AS total_read,
  CASE (heap_blks_hit + heap_blks_read)::float
    WHEN 0 THEN 'Insufficient data'
    ELSE (heap_blks_hit / (heap_blks_hit + heap_blks_read)::float)::text
  END ratio
FROM
  pg_statio_user_tables
ORDER BY
  heap_blks_hit / (heap_blks_hit + heap_blks_read + 1)::float DESC;
"""
  end
end
