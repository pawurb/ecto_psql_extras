defmodule EctoPSQLExtras.Extensions do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "Available and installed extensions",
      order_by: [installed_version: :asc],
      columns: [
        %{name: :name, type: :string},
        %{name: :default_version, type: :string},
        %{name: :installed_version, type: :string},
        %{name: :comment, type: :string}
      ]
    }
  end

  def query do
    """
    /* Available and installed extensions */

    SELECT name, default_version, installed_version, comment
    FROM pg_available_extensions
    ORDER BY installed_version;
    """
  end
end
