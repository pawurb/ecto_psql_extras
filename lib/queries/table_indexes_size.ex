defmodule EctoPSQLExtras.TableIndexesSize do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "Total size of all the indexes on each table, descending by size",
      index: 14,
      order_by: [index_size: :desc],
      columns: [
        %{name: :schema, type: :string},
        %{name: :table, type: :string},
        %{name: :index_size, type: :bytes}
      ]
    }
  end

  def query(_args \\ []) do
    """
    /* ECTO_PSQL_EXTRAS: Total size of all the indexes on each table, descending by size */

    SELECT n.nspname AS schema, c.relname AS table, pg_indexes_size(c.oid) AS index_size
    FROM pg_class c
    LEFT JOIN pg_namespace n ON (n.oid = c.relnamespace)
    WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
    AND n.nspname !~ '^pg_toast'
    AND c.relkind IN ('r', 'm')
    ORDER BY pg_indexes_size(c.oid) DESC;
    """
  end
end
