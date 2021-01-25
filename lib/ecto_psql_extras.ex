defmodule EctoPSQLExtras do
  @moduledoc """
  The entry point for each function.
  """

  @callback info :: %{
              required(:title) => binary,
              required(:columns) => [%{name: atom, type: atom}],
              optional(:order_by) => [{atom, :asc | :desc}],
              optional(:default_args) => list,
              optional(:args_for_select) => list
            }

  @callback query :: binary

  @doc """
  Returns all queries and their modules.

  If a repository is given, it will be queried for extensions support
  and special queries will be included if available.
  """
  def queries(repo \\ nil) do
    %{
      bloat: EctoPSQLExtras.Bloat,
      blocking: EctoPSQLExtras.Blocking,
      cache_hit: EctoPSQLExtras.CacheHit,
      extensions: EctoPSQLExtras.Extensions,
      table_cache_hit: EctoPSQLExtras.TableCacheHit,
      index_cache_hit: EctoPSQLExtras.IndexCacheHit,
      index_size: EctoPSQLExtras.IndexSize,
      index_usage: EctoPSQLExtras.IndexUsage,
      locks: EctoPSQLExtras.Locks,
      all_locks: EctoPSQLExtras.AllLocks,
      long_running_queries: EctoPSQLExtras.LongRunningQueries,
      mandelbrot: EctoPSQLExtras.Mandelbrot,
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
    |> Map.merge(pg_stat_statements_queries(repo))
  end

  @pg_stat_statements_query "select installed_version from pg_available_extensions where name='pg_stat_statements'"

  defp pg_stat_statements_queries(repo) do
    case repo && pg_stat_statements_version(repo) do
      nil ->
        %{}

      vsn when vsn < {1, 8, 0} ->
        %{calls: EctoPSQLExtras.CallsLegacy, outliers: EctoPSQLExtras.OutliersLegacy}

      _vsn ->
        %{calls: EctoPSQLExtras.Calls, outliers: EctoPSQLExtras.Outliers}
    end
  end

  defp pg_stat_statements_version(repo) do
    case repo.query!(@pg_stat_statements_query).rows do
      [[value]] when is_binary(value) -> Postgrex.Utils.parse_version(value)
      _ -> nil
    end
  end

  @doc """
  Run a query with `name`, on `repo`, in the given `format`.

  `format` is either `:ascii` or `:raw`.
  """
  def query(name, repo, opts \\ []) do
    query_module = Map.fetch!(queries(repo), name)
    opts = prepare_opts(opts, query_module.info[:default_args])

    result = repo.query!(
      query_module.query(
        Keyword.fetch!(opts, :args)
      )
    )

    format(
      Keyword.fetch!(opts, :format),
      query_module.info, result
    )
  end

  @doc """
  Run `bloat` query on `repo`, in the given `format`.

  `format` is either `:ascii` or `:raw`
  """
  def bloat(repo, opts \\ []), do: query(:bloat, repo, opts)

  @doc """
  Run `blocking` query on `repo`, in the given `format`.

  `format` is either `:ascii` or `:raw`
  """
  def blocking(repo, opts \\ []), do: query(:blocking, repo, opts)

  @doc """
  Run `cache_hit` query on `repo`, in the given `format`.

  `format` is either `:ascii` or `:raw`
  """
  def cache_hit(repo, opts \\ []), do: query(:cache_hit, repo, opts)

  @doc """
  Run `extensions` query on `repo`, in the given `format`.

  `format` is either `:ascii` or `:raw`
  """
  def extensions(repo, opts \\ []), do: query(:extensions, repo, opts)

  @doc """
  Run `table_cache_hit` query on `repo`, in the given `format`.

  `format` is either `:ascii` or `:raw`
  """
  def table_cache_hit(repo, opts \\ []), do: query(:table_cache_hit, repo, opts)

  @doc """
  Run `index_cache_hit` query on `repo`, in the given `format`.

  `format` is either `:ascii` or `:raw`
  """
  def index_cache_hit(repo, opts \\ []), do: query(:index_cache_hit, repo, opts)

  @doc """
  Run `index_size` query on `repo`, in the given `format`.

  `format` is either `:ascii` or `:raw`
  """
  def index_size(repo, opts \\ []), do: query(:index_size, repo, opts)

  @doc """
  Run `index_usage` query on `repo`, in the given `format`.

  `format` is either `:ascii` or `:raw`
  """
  def index_usage(repo, opts \\ []), do: query(:index_usage, repo, opts)

  @doc """
  Run `locks` query on `repo`, in the given `format`.

  `format` is either `:ascii` or `:raw`
  """
  def locks(repo, opts \\ []), do: query(:locks, repo, opts)

  @doc """
  Run `all_locks` query on `repo`, in the given `format`.

  `format` is either `:ascii` or `:raw`
  """
  def all_locks(repo, opts \\ []), do: query(:all_locks, repo, opts)

  @doc """
  Run `long_running_queries` query on `repo`, in the given `format`.

  `format` is either `:ascii` or `:raw`
  """
  def long_running_queries(repo, opts \\ []), do: query(:long_running_queries, repo, opts)

  @doc """
  Run `mandelbrot` query on `repo`, in the given `format`.

  `format` is either `:ascii` or `:raw`
  """
  def mandelbrot(repo, opts \\ []), do: query(:mandelbrot, repo, opts)

  @doc """
  Run `records_rank` query on `repo`, in the given `format`.

  `format` is either `:ascii` or `:raw`
  """
  def records_rank(repo, opts \\ []), do: query(:records_rank, repo, opts)

  @doc """
  Run `seq_scans` query on `repo`, in the given `format`.

  `format` is either `:ascii` or `:raw`
  """
  def seq_scans(repo, opts \\ []), do: query(:seq_scans, repo, opts)

  @doc """
  Run `table_indexes_size` query on `repo`, in the given `format`.

  `format` is either `:ascii` or `:raw`
  """
  def table_indexes_size(repo, opts \\ []), do: query(:table_indexes_size, repo, opts)

  @doc """
  Run `table_size` query on `repo`, in the given `format`.

  `format` is either `:ascii` or `:raw`
  """
  def table_size(repo, opts \\ []), do: query(:table_size, repo, opts)

  @doc """
  Run `total_index_size` query on `repo`, in the given `format`.

  `format` is either `:ascii` or `:raw`
  """
  def total_index_size(repo, opts \\ []), do: query(:total_index_size, repo, opts)

  @doc """
  Run `total_table_size` query on `repo`, in the given `format`.

  `format` is either `:ascii` or `:raw`
  """
  def total_table_size(repo, opts \\ []), do: query(:total_table_size, repo, opts)

  @doc """
  Run `unused_indexes` query on `repo`, in the given `format`.

  `format` is either `:ascii` or `:raw`
  """
  def unused_indexes(repo, opts \\ []), do: query(:unused_indexes, repo, opts)

  @doc """
  Run `vacuum_stats` query on `repo`, in the given `format`.

  `format` is either `:ascii` or `:raw`
  """
  def vacuum_stats(repo, opts \\ []), do: query(:vacuum_stats, repo, opts)

  @doc """
  Run `kill_all` query on `repo`, in the given `format`.

  `format` is either `:ascii` or `:raw`
  """
  def kill_all(repo, opts \\ []), do: query(:kill_all, repo, opts)

  @doc """
  Run `calls` query on `repo`, in the given `format`.

  `format` is either `:ascii` or `:raw`
  """
  def calls(repo, opts \\ []), do: query(:calls, repo, opts)

  @doc """
  Run `outliers` query on `repo`, in the given `format`.

  `format` is either `:ascii` or `:raw`
  """
  def outliers(repo, opts \\ []), do: query(:outliers, repo, opts)

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

  defp prepare_opts(opts, default_args) do
    format = Keyword.get(opts, :format, :ascii)

    args = Keyword.merge(
      default_args || [],
      opts[:args] || []
    )

    [
      format: format,
      args: args
    ]
  end
end
