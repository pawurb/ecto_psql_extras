defmodule EctoPSQLExtras do
  @queries %{
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

  def query(name, repo, format \\ :ascii) do
    query_module = @queries[name]
    result = repo.query(query_module.query) |> elem(1)

    if format == :ascii do
      rows = if length(result.rows) == 0 do
        [["No results", nil]]
      else
        Enum.map result.rows, fn n -> parse(n) end
      end

      TableRex.quick_render!(
        rows, result.columns, query_module.title
      ) |> IO.puts
    end

    if format == :raw do
      result
    end
  end

  defp parse(list) do
    Enum.map list, fn n ->
      if IEx.Info.info(n) |> Enum.at(0) |> elem(1) == "Decimal" do
        Decimal.to_float n
      else
        if IEx.Info.info(n) |> Enum.at(0) |> elem(1) == "Postgrex.Interval" do
          inspect n
        else
          n
        end
      end
    end
  end
end
