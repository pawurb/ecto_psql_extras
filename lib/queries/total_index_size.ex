defmodule EctoPSQLExtras.TotalIndexSize do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "Total size of all indexes in MB",
      limit: 1,
      columns: [
        %{name: :size, type: :string}
      ]
    }
  end

  def query do
    """
    /* Total size of all indexes in MB */

    SELECT pg_size_pretty(sum(c.relpages::bigint*8192)::bigint) AS size
    FROM pg_class c
    LEFT JOIN pg_namespace n ON (n.oid = c.relnamespace)
    WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
    AND n.nspname !~ '^pg_toast'
    AND c.relkind='i';
    """
  end
end
