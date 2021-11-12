defmodule EctoPSQLExtras.SeqScans do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "Count of sequential scans by table descending by order",
      index: 19,
      order_by: [count: :desc],
      columns: [
        %{name: :schema, type: :string},
        %{name: :name, type: :string},
        %{name: :count, type: :integer}
      ]
    }
  end

  def query(_args \\ []) do
    """
    /* ECTO_PSQL_EXTRAS: Count of sequential scans by table descending by order */

    SELECT schemaname AS schema, relname AS name,
           seq_scan as count
    FROM
      pg_stat_user_tables
    ORDER BY seq_scan DESC;
    """
  end
end
