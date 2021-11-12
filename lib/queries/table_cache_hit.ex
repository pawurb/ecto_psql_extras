defmodule EctoPSQLExtras.TableCacheHit do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "Calculates your cache hit rate for reading tables",
      index: 2,
      order_by: [ratio: :desc],
      columns: [
        %{name: :schema, type: :string},
        %{name: :name, type: :string},
        %{name: :buffer_hits, type: :integer},
        %{name: :block_reads, type: :integer},
        %{name: :total_read, type: :integer},
        %{name: :ratio, type: :numeric}
      ]
    }
  end

  def query(_args \\ []) do
    """
    /* ECTO_PSQL_EXTRAS: Calculates your cache hit rate for reading tables */

    SELECT
      schemaname AS schema, relname AS name,
      heap_blks_hit AS buffer_hits,
      heap_blks_read AS block_reads,
      heap_blks_hit + heap_blks_read AS total_read,
      CASE (heap_blks_hit + heap_blks_read)::float
        WHEN 0 THEN NULL
        ELSE (heap_blks_hit / (heap_blks_hit + heap_blks_read)::float)
      END ratio
    FROM
      pg_statio_user_tables
    ORDER BY
      heap_blks_hit / (heap_blks_hit + heap_blks_read + 1)::float DESC;
    """
  end
end
