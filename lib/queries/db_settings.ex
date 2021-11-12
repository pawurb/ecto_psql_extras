defmodule EctoPSQLExtras.DbSettings do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "Queries that have the highest frequency of execution",
      index: 10,
      columns: [
        %{name: :name, type: :string},
        %{name: :setting, type: :string},
        %{name: :unit, type: :string},
        %{name: :short_desc, type: :string}
      ]
    }
  end

  def query(_args \\ []) do
    """
    /* ECTO_PSQL_EXTRAS: Values of selected PostgreSQL settings */

    SELECT name, setting, unit, short_desc FROM pg_settings
    WHERE name IN (
      'max_connections', 'shared_buffers', 'effective_cache_size',
      'maintenance_work_mem', 'checkpoint_completion_target', 'wal_buffers',
      'default_statistics_target', 'random_page_cost', 'effective_io_concurrency',
      'work_mem', 'min_wal_size', 'max_wal_size'
    );
    """
  end
end

