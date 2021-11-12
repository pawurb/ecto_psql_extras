defmodule EctoPSQLExtras.CacheHit do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "Index and table hit rate",
      index: 1,
      columns: [
        %{name: :name, type: :string},
        %{name: :ratio, type: :numeric}
      ]
    }
  end

  def query(_args \\ []) do
    """
    /* ECTO_PSQL_EXTRAS: Index and table hit rate */

    SELECT
      'index hit rate' AS name,
      (sum(idx_blks_hit)) / nullif(sum(idx_blks_hit + idx_blks_read),0) AS ratio
    FROM pg_statio_user_indexes
    UNION ALL
    SELECT
     'table hit rate' AS name,
      sum(heap_blks_hit) / nullif(sum(heap_blks_hit) + sum(heap_blks_read),0) AS ratio
    FROM pg_statio_user_tables;
    """
  end
end
