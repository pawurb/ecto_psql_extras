defmodule EctoPSQLExtras.RecordsRank do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "All tables and the number of rows in each ordered by number of rows descending",
      index: 20,
      order_by: [estimated_count: :desc],
      columns: [
        %{name: :schema, type: :string},
        %{name: :name, type: :string},
        %{name: :estimated_count, type: :integer}
      ]
    }
  end

  def query(_args \\ []) do
    """
    /* ECTO_PSQL_EXTRAS: All tables and the number of rows in each ordered by number of rows descending */

    SELECT
      schemaname AS schema, relname AS name,
      n_live_tup AS estimated_count
    FROM
      pg_stat_user_tables
    ORDER BY
      n_live_tup DESC;
    """
  end
end
