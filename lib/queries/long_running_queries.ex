defmodule EctoPSQLExtras.LongRunningQueries do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "All queries longer than the threshold by descending duration",
      index: 22,
      order_by: [duration: :desc],
      default_args: [threshold: "500 milliseconds"],
      columns: [
        %{name: :pid, type: :int},
        %{name: :duration, type: :interval},
        %{name: :query, type: :string}
      ]
    }
  end

  def query(args \\ []) do
    """
    /* ECTO_PSQL_EXTRAS: All queries longer than the threshold by descending duration */

    SELECT
      pid,
      now() - pg_stat_activity.query_start AS duration,
      query AS query
    FROM
      pg_stat_activity
    WHERE
      pg_stat_activity.query <> ''::text
      AND state <> 'idle'
      AND now() - pg_stat_activity.query_start > interval '<%= threshold %>'
    ORDER BY
      now() - pg_stat_activity.query_start DESC;
    """ |> EEx.eval_string(args)
  end
end
