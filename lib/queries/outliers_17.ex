defmodule EctoPSQLExtras.Outliers17 do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "Queries that have longest execution time in aggregate",
      index: 8,
      order_by: [exec_time: :desc],
      default_args: [limit: 10],
      columns: [
        %{name: :query, type: :string},
        %{name: :exec_time, type: :interval},
        %{name: :prop_exec_time, type: :percent},
        %{name: :calls, type: :integer},
        %{name: :sync_io_time, type: :interval}
      ]
    }
  end

  def query(args \\ []) do
    """
    /* ECTO_PSQL_EXTRAS: Queries that have longest execution time in aggregate */

    SELECT query AS query,
    interval '1 millisecond' * total_exec_time AS exec_time,
    (total_exec_time/sum(total_exec_time) OVER()) AS prop_exec_time,
    calls,
    interval '1 millisecond' * (shared_blk_read_time + shared_blk_write_time) AS sync_io_time
    FROM pg_stat_statements WHERE userid = (SELECT usesysid FROM pg_user WHERE usename = current_user LIMIT 1)
    AND query NOT LIKE '/* ECTO_PSQL_EXTRAS:%'
    ORDER BY total_exec_time DESC
    LIMIT <%= limit %>;
    """
    |> EEx.eval_string(args)
  end
end
