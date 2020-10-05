defmodule EctoPSQLExtras.RecordsRank do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "All tables and the number of rows in each ordered by number of rows descending",
      order_by: [estimated_count: :desc],
      columns: [
        %{name: :name, type: :string},
        %{name: :estimated_count, type: :integer}
      ]
    }
  end

  def query do
    """
    /* All tables and the number of rows in each ordered by number of rows descending */

    SELECT
      relname AS name,
      n_live_tup AS estimated_count
    FROM
      pg_stat_user_tables
    ORDER BY
      n_live_tup DESC;
    """
  end
end
