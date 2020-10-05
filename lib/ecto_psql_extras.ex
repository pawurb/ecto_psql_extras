defmodule EctoPSQLExtras do
  @moduledoc """
  The entry point for each function.
  """

  @callback info :: %{
              required(:title) => binary,
              required(:columns) => [%{name: atom, type: atom}],
              optional(:order_by) => [{atom, :asc | :desc}],
              optional(:limit) => pos_integer
            }

  @callback query :: binary

  @doc """
  Returns all queries and their modules.
  """
  def queries do
    %{
      bloat: EctoPSQLExtras.Bloat,
      blocking: EctoPSQLExtras.Blocking,
      cache_hit: EctoPSQLExtras.CacheHit,
      calls: EctoPSQLExtras.Calls,
      extensions: EctoPSQLExtras.Extensions,
      table_cache_hit: EctoPSQLExtras.TableCacheHit,
      index_cache_hit: EctoPSQLExtras.IndexCacheHit,
      index_size: EctoPSQLExtras.IndexSize,
      index_usage: EctoPSQLExtras.IndexUsage,
      locks: EctoPSQLExtras.Locks,
      all_locks: EctoPSQLExtras.AllLocks,
      long_running_queries: EctoPSQLExtras.LongRunningQueries,
      mandelbrot: EctoPSQLExtras.Mandelbrot,
      outliers: EctoPSQLExtras.Outliers,
      records_rank: EctoPSQLExtras.RecordsRank,
      seq_scans: EctoPSQLExtras.SeqScans,
      table_indexes_size: EctoPSQLExtras.TableIndexesSize,
      table_size: EctoPSQLExtras.TableSize,
      total_index_size: EctoPSQLExtras.TotalIndexSize,
      total_table_size: EctoPSQLExtras.TotalTableSize,
      unused_indexes: EctoPSQLExtras.UnusedIndexes,
      vacuum_stats: EctoPSQLExtras.VacuumStats,
      kill_all: EctoPSQLExtras.KillAll
    }
  end

  @doc """
  Run a query with `name`, on `repo`, in the given `format`.

  `format` is either `:ascii` or `:raw`.
  """
  def query(name, repo, format \\ :ascii) do
    query_module = queries()[name]
    result = repo.query!(query_module.query)
    format(format, query_module.info, result)
  end

  defp format(:ascii, info, result) do
    rows =
      if result.rows == [] do
        [["No results", nil]]
      else
        Enum.map(result.rows, &parse_row/1)
      end

    names = Enum.map(info.columns, & &1.name)

    rows
    |> TableRex.quick_render!(names, info.title)
    |> IO.puts()
  end

  defp format(:raw, _info, result) do
    result
  end

  defp parse_row(list) do
    Enum.map(list, &parse_column/1)
  end

  defp parse_column(%struct{} = decimal) when struct == Decimal, do: Decimal.to_float(decimal)
  defp parse_column(binary) when is_binary(binary), do: binary
  defp parse_column(other), do: inspect(other)
end
