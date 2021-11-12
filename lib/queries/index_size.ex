defmodule EctoPSQLExtras.IndexSize do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "The size of indexes, descending by size",
      index: 18,
      order_by: [size: :desc],
      columns: [
        %{name: :schema, type: :string},
        %{name: :name, type: :string},
        %{name: :size, type: :bytes}
      ]
    }
  end

  def query(_args \\ []) do
    """
    /* ECTO_PSQL_EXTRAS: The size of indexes, descending by size */

    SELECT n.nspname AS schema, c.relname AS name, sum(c.relpages::bigint*8192)::bigint AS size
    FROM pg_class c
    LEFT JOIN pg_namespace n ON (n.oid = c.relnamespace)
    WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
    AND n.nspname !~ '^pg_toast'
    AND c.relkind='i'
    GROUP BY (n.nspname, c.relname)
    ORDER BY sum(c.relpages) DESC;
    """
  end
end
