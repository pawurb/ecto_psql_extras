defmodule EctoPSQLExtras.NullIndexes do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "Find indexes with a high ratio of NULL values",
      index: 5,
      default_args: [min_relation_size_mb: 0],
      columns: [
        %{name: :oid, type: :string},
        %{name: :index, type: :string},
        %{name: :index_size, type: :string},
        %{name: :unique, type: :boolean},
        %{name: :indexed_column, type: :string},
        %{name: :null_frac, type: :string},
        %{name: :expected_saving, type: :string}
      ]
    }
  end

  def query(args \\ []) do
    """
    /* ECTO_PSQL_EXTRAS: Find indexes with a high ratio of NULL values */

    SELECT
        c.oid,
        c.relname AS index,
        pg_size_pretty(pg_relation_size(c.oid)) AS index_size,
        i.indisunique AS unique,
        a.attname AS indexed_column,
        CASE s.null_frac
            WHEN 0 THEN ''
            ELSE to_char(s.null_frac * 100, '999.00%')
        END AS null_frac,
        pg_size_pretty((pg_relation_size(c.oid) * s.null_frac)::bigint) AS expected_saving
    FROM
        pg_class c
        JOIN pg_index i ON i.indexrelid = c.oid
        JOIN pg_attribute a ON a.attrelid = c.oid
        JOIN pg_class c_table ON c_table.oid = i.indrelid
        JOIN pg_indexes ixs ON c.relname = ixs.indexname
        LEFT JOIN pg_stats s ON s.tablename = c_table.relname AND a.attname = s.attname
    WHERE
        -- Primary key cannot be partial
        NOT i.indisprimary
        -- Exclude already partial indexes
        AND i.indpred IS NULL
        -- Exclude composite indexes
        AND array_length(i.indkey, 1) = 1
        -- Exclude indexes without null_frac ratio
        AND coalesce(s.null_frac, 0) != 0
        -- Larger than threshold
        AND pg_relation_size(c.oid) > <%= min_relation_size_mb %> * 1024 ^ 2
    ORDER BY
      pg_relation_size(c.oid) * s.null_frac DESC;
    """ |> EEx.eval_string(args)
  end
end

