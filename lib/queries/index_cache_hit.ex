defmodule EctoPSQLExtras.IndexCacheHit do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "Calculates your cache hit rate for reading indexes",
      order_by: [ratio: :desc],
      columns: [
        %{name: :name, type: :string},
        %{name: :buffer_hits, type: :integer},
        %{name: :block_reads, type: :integer},
        %{name: :total_read, type: :integer},
        %{name: :ratio, type: :string}
      ]
    }
  end

  def query do
    """
    /* Calculates your cache hit rate for reading indexes */

    SELECT
      relname AS name,
      idx_blks_hit AS buffer_hits,
      idx_blks_read AS block_reads,
      idx_blks_hit + idx_blks_read AS total_read,
      CASE (idx_blks_hit + idx_blks_read)::float
        WHEN 0 THEN 'Insufficient data'
        ELSE (idx_blks_hit / (idx_blks_hit + idx_blks_read)::float)::text
      END ratio
    FROM
      pg_statio_user_tables
    ORDER BY
      idx_blks_hit / (idx_blks_hit + idx_blks_read + 1)::float DESC;
    """
  end
end
