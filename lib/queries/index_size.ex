defmodule EctoPSQLExtras.IndexSize do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "The size of indexes, descending by size",
      order_by: [size: :desc],
      columns: [
        %{name: :name, type: :string},
        %{name: :size, type: :bytes}
      ]
    }
  end

  def query do
    """
    /* The size of indexes, descending by size */

    SELECT c.relname AS name, sum(c.relpages::bigint*8192)::bigint AS size
    FROM pg_class c
    LEFT JOIN pg_namespace n ON (n.oid = c.relnamespace)
    WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
    AND n.nspname !~ '^pg_toast'
    AND c.relkind='i'
    GROUP BY c.relname
    ORDER BY sum(c.relpages) DESC;
    """
  end
end
