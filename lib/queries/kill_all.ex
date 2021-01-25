defmodule EctoPSQLExtras.KillAll do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "Kill all the active database connections",
      columns: [
        %{name: :killed, type: :boolean}
      ]
    }
  end

  def query(_args \\ []) do
    """
    /* ECTO_PSQL_EXTRAS: Kill all the active database connections */

    SELECT pg_terminate_backend(pid) AS killed FROM pg_stat_activity
      WHERE pid <> pg_backend_pid()
      AND query <> '<insufficient privilege>'
      AND datname = current_database();
    """
  end
end
