defmodule EctoPSQLExtras.Outliers do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "10 queries that have longest execution time in aggregate",
      order_by: [total_time: :desc],
      limit: 10,
      columns: [
        %{name: :query, type: :string},
        %{name: :exec_time, type: :interval},
        %{name: :prop_exec_time, type: :string},
        %{name: :ncalls, type: :string},
        %{name: :sync_io_time, type: :interval}
      ]
    }
  end

  def query do
    """
    /* 10 queries that have longest execution time in aggregate */

    SELECT query AS qry,
    interval '1 millisecond' * total_time AS exec_time,
    to_char((total_time/sum(total_time) OVER()) * 100, 'FM90D0') || '%'  AS prop_exec_time,
    to_char(calls, 'FM999G999G999G990') AS ncalls,
    interval '1 millisecond' * (blk_read_time + blk_write_time) AS sync_io_time
    FROM pg_stat_statements WHERE userid = (SELECT usesysid FROM pg_user WHERE usename = current_user LIMIT 1)
    ORDER BY total_time DESC
    LIMIT 10;
    """
  end
end
