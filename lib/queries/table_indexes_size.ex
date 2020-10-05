defmodule EctoPSQLExtras.TableIndexesSize do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "Total size of all the indexes on each table, descending by size",
      order_by: [size: :desc],
      columns: [
        %{name: :name, type: :string},
        %{name: :size, type: :string}
      ]
    }
  end

  def query do
    """
    /* Total size of all the indexes on each table, descending by size */

    SELECT c.relname AS table,
      pg_size_pretty(pg_indexes_size(c.oid)) AS index_size
    FROM pg_class c
    LEFT JOIN pg_namespace n ON (n.oid = c.relnamespace)
    WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
    AND n.nspname !~ '^pg_toast'
    AND c.relkind IN ('r', 'm')
    ORDER BY pg_indexes_size(c.oid) DESC;
    """
  end
end
