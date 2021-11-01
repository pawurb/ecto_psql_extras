defmodule EctoPSQLExtras.Diagnose do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "Generate a PostgreSQL healthcheck report",
      order_by: [ok: :asc],
      columns: [
        %{name: :ok, type: :boolean},
        %{name: :check_name, type: :string},
        %{name: :message, type: :string}
      ]
    }
  end

  def query(_args \\ []) do
    # placeholder
  end
end
