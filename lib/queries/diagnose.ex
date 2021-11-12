defmodule EctoPSQLExtras.Diagnose do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "Display a PostgreSQL healthcheck report",
      index: 0,
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
