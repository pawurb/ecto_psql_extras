defmodule EctoPSQLExtras.SeqScans do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "Count of sequential scans by table descending by order",
      order_by: [count: :desc],
      columns: [
        %{name: :name, type: :string},
        %{name: :count, type: :integer}
      ]
    }
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
