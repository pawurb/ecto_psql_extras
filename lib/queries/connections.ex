defmodule EctoPSQLExtras.Connections do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "Returns the list of all active database connections",
      columns: [
        %{name: :username, type: :string},
        %{name: :client_address, type: :string},
        %{name: :application_name, type: :string}
      ]
    }
  end

  def query(_args \\ []) do
    """
    /* ECTO_PSQL_EXTRAS: Returns the list of all active database connections */

    SELECT usename as username, client_addr::text as client_address, application_name FROM pg_stat_activity
      WHERE datname = current_database();
    """
  end
end
