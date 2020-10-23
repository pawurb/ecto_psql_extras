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
  def queries(repo \\ nil) do
    # Detect older versions of pg_stat_statements and use different column names
    legacy = repo && pg_stat_statements_version(repo) < {1, 8, 0}

    %{
      bloat: EctoPSQLExtras.Bloat,
      blocking: EctoPSQLExtras.Blocking,
      cache_hit: EctoPSQLExtras.CacheHit,
      calls: if(legacy, do: EctoPSQLExtras.CallsLegacy, else: EctoPSQLExtras.Calls),
      extensions: EctoPSQLExtras.Extensions,
      table_cache_hit: EctoPSQLExtras.TableCacheHit,
      index_cache_hit: EctoPSQLExtras.IndexCacheHit,
      index_size: EctoPSQLExtras.IndexSize,
      index_usage: EctoPSQLExtras.IndexUsage,
      locks: EctoPSQLExtras.Locks,
      all_locks: EctoPSQLExtras.AllLocks,
      long_running_queries: EctoPSQLExtras.LongRunningQueries,
      mandelbrot: EctoPSQLExtras.Mandelbrot,
      outliers: if(legacy, do: EctoPSQLExtras.OutliersLegacy, else: EctoPSQLExtras.Outliers),
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
    query_module = Map.fetch!(queries(repo), name)
    result = repo.query!(query_module.query)
    format(format, query_module.info, result)
  end

  defp format(:ascii, info, result) do
    names = Enum.map(info.columns, & &1.name)
    types = Enum.map(info.columns, & &1.type)

    rows =
      if result.rows == [] do
        [["No results", nil]]
      else
        Enum.map(result.rows, &parse_row(&1, types))
      end

    rows
    |> TableRex.quick_render!(names, info.title)
    |> IO.puts()
  end

  defp format(:raw, _info, result) do
    result
  end

  defp parse_row(list, types) do
    list
    |> Enum.zip(types)
    |> Enum.map(&format_value/1)
  end

  @doc false
  def format_value({%struct{} = value, _}) when struct in [Decimal, Postgrex.Interval],
    do: struct.to_string(value)

  def format_value({nil, _}), do: ""
  def format_value({number, :percent}), do: format_percent(number)
  def format_value({integer, :bytes}) when is_integer(integer), do: format_bytes(integer)
  def format_value({string, :string}), do: String.replace(string, "\n", "")
  def format_value({binary, _}) when is_binary(binary), do: binary
  def format_value({other, _}), do: inspect(other)

  defp format_percent(number) do
    number |> Kernel.*(100.0) |> Float.round(1) |> Float.to_string()
  end

  defp format_bytes(bytes) do
    cond do
      bytes >= memory_unit(:TB) -> format_bytes(bytes, :TB)
      bytes >= memory_unit(:GB) -> format_bytes(bytes, :GB)
      bytes >= memory_unit(:MB) -> format_bytes(bytes, :MB)
      bytes >= memory_unit(:KB) -> format_bytes(bytes, :KB)
      true -> format_bytes(bytes, :B)
    end
  end

  defp format_bytes(bytes, :B) when is_integer(bytes), do: "#{bytes} bytes"

  defp format_bytes(bytes, unit) when is_integer(bytes) do
    value = bytes / memory_unit(unit)
    "#{:erlang.float_to_binary(value, decimals: 1)} #{unit}"
  end

  defp memory_unit(:TB), do: 1024 * 1024 * 1024 * 1024
  defp memory_unit(:GB), do: 1024 * 1024 * 1024
  defp memory_unit(:MB), do: 1024 * 1024
  defp memory_unit(:KB), do: 1024

  def pg_stat_statements_version(repo) do
    [[value]] =
      repo.query!(
        "select installed_version from pg_available_extensions where name='pg_stat_statements'"
      ).rows

    value && Postgrex.Utils.parse_version(value)
  end
end
