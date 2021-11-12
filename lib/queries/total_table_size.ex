defmodule EctoPSQLExtras.TotalTableSize do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "Size of the tables (including indexes), descending by size",
      index: 11,
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
    /* ECTO_PSQL_EXTRAS: Size of the tables (including indexes), descending by size */

    SELECT n.nspname AS schema, c.relname AS name, pg_total_relation_size(c.oid) AS size
    FROM pg_class c
    LEFT JOIN pg_namespace n ON (n.oid = c.relnamespace)
    WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
    AND n.nspname !~ '^pg_toast'
    AND c.relkind IN ('r', 'm')
    ORDER BY pg_total_relation_size(c.oid) DESC;
    """
  end
end
