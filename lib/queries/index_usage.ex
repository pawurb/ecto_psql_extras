defmodule EctoPSQLExtras.IndexUsage do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "Index hit rate (effective databases are at 99% and up)",
      index: 17,
      columns: [
        %{name: :schema, type: :string},
        %{name: :name, type: :string},
        %{name: :percent_of_times_index_used, type: :numeric},
        %{name: :rows_in_table, type: :int}
      ]
    }
  end

  def query(_args \\ []) do
    """
    /* ECTO_PSQL_EXTRAS: Index hit rate (effective databases are at 99% and up) */

    SELECT schemaname AS schema, relname AS name,
       CASE idx_scan
         WHEN 0 THEN NULL
         ELSE (100 * idx_scan / (seq_scan + idx_scan))
       END percent_of_times_index_used,
       n_live_tup rows_in_table
     FROM
       pg_stat_user_tables
     ORDER BY
       n_live_tup DESC;
    """
  end
end
