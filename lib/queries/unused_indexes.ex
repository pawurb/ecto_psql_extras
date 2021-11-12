defmodule EctoPSQLExtras.UnusedIndexes do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "Unused and almost unused indexes",
      index: 4,
      default_args: [min_scans: 50],
      columns: [
        %{name: :schema, type: :string},
        %{name: :table, type: :string},
        %{name: :index, type: :string},
        %{name: :index_size, type: :bytes},
        %{name: :index_scans, type: :integer}
      ]
    }
  end

  def query(args \\ []) do
    """
    /* ECTO_PSQL_EXTRAS: Unused and almost unused indexes */
    /* Ordered by their size relative to the number of index scans.
    Exclude indexes of very small tables (less than 5 pages),
    where the planner will almost invariably select a sequential scan,
    but may not in the future as the table grows */

    SELECT
      schemaname AS schema,
      relname AS table,
      indexrelname AS index,
      pg_relation_size(i.indexrelid) AS index_size,
      idx_scan as index_scans
    FROM pg_stat_user_indexes ui
    JOIN pg_index i ON ui.indexrelid = i.indexrelid
    WHERE NOT indisunique AND idx_scan < <%= min_scans %> AND pg_relation_size(relid) > 5 * 8192
    ORDER BY pg_relation_size(i.indexrelid) / nullif(idx_scan, 0) DESC NULLS FIRST,
    pg_relation_size(i.indexrelid) DESC;
    """ |> EEx.eval_string(args)
  end
end
