defmodule EctoPSQLExtras.SSLUsed do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "Check if SSL connection is used",
      columns: [
        %{name: :ssl_is_used, type: :boolean}
      ]
    }
  end

  def query(_args \\ []) do
    """
    /* ECTO_PSQL_EXTRAS: Check if SSL connection is used  */
    SELECT ssl_is_used();
    """
  end
end
