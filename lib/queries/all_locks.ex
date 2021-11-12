defmodule EctoPSQLExtras.AllLocks do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "Queries with active locks",
      index: 25,
      columns: [
        %{name: :pid, type: :integer},
        %{name: :relname, type: :string},
        %{name: :transactionid, type: :integer},
        %{name: :granted, type: :boolean},
        %{name: :query_snippet, type: :string},
        %{name: :mode, type: :string},
        %{name: :age, type: :interval}
      ]
    }
  end

  def query(_args \\ []) do
    """
    /* ECTO_PSQL_EXTRAS: Queries with active locks */

    SELECT
      pg_stat_activity.pid,
      pg_class.relname,
      pg_locks.transactionid,
      pg_locks.granted,
      pg_locks.mode,
      pg_stat_activity.query AS query_snippet,
      age(now(),pg_stat_activity.query_start) AS "age"
    FROM pg_stat_activity,pg_locks left
    OUTER JOIN pg_class
      ON (pg_locks.relation = pg_class.oid)
    WHERE pg_stat_activity.query <> '<insufficient privilege>'
      AND pg_locks.pid = pg_stat_activity.pid
      AND pg_stat_activity.pid <> pg_backend_pid() order by query_start;
    """
  end
end
