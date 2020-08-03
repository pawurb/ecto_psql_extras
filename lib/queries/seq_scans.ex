defmodule EctoPSQLExtras.SeqScans do
  def title do
    "Count of sequential scans by table descending by order"
  end

  def query do
"""
/* Count of sequential scans by table descending by order */

SELECT relname AS name,
       seq_scan as count
FROM
  pg_stat_user_tables
ORDER BY seq_scan DESC;
"""
  end
end
