defmodule EctoPSQLExtras.Indexes do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "List all the indexes with their corresponding tables and columns",
      index: 4,
      columns: [
        %{name: :schemaname, type: :string},
        %{name: :indexname, type: :string},
        %{name: :tablename, type: :string},
        %{name: :columns, type: :string}
      ]
    }
  end

  def query(_args \\ []) do
    """
    /* ECTO_PSQL_EXTRAS: List all the indexes with their corresponding tables and columns */
    SELECT
    schemaname,
    indexname,
    tablename,
    rtrim(split_part(indexdef, '(', 2), ')') as columns
    FROM pg_indexes
    where tablename in (select relname from pg_statio_user_tables);
    """
  end
end
