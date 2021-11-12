defmodule EctoPSQLExtras.DiagnoseLogic do
  @moduledoc """
  Diagnose report logic
  """

  @table_cache_hit_min_expected 0.985
  @index_cache_hit_min_expected "0.985"
  @unused_indexes_max_scans 20
  @unused_indexes_min_size_bytes 1000000
  @null_indexes_min_size_mb 1 # 1 MB
  @null_min_null_frac_percent 50 # 50%
  @bloat_min_value 10.0
  @outliers_min_exec_ratio 33 # 33%

  def run(repo) do
    try  do
      %{
        columns: ["ok", "check_name", "message"],
        rows: [
          table_cache_hit(repo),
          index_cache_hit(repo),
          unused_indexes(repo),
          null_indexes(repo),
          bloat(repo),
          duplicate_indexes(repo),
          outliers(repo),
          ssl_used(repo),
        ]
      }
    rescue
      _ ->
        %{
          columns: ["ok", "check_name", "message"],
          rows: [
            [false, "diagnose_error", "There was an error when generating your diagnose report"]
          ]
        }
    end
  end

  defp table_cache_hit(repo) do
    table_cache_hit_val = EctoPSQLExtras.cache_hit(repo, format: :raw).rows
    |> Enum.at(1) |> Enum.at(1)

    [ok, message] = case table_cache_hit_val do
      nil ->
        [false, "Table cache hit ratio is not yet reported."]
      %Decimal{} = val ->
        val = Decimal.to_float(val) |> Float.round(6)

        if (val >= @table_cache_hit_min_expected ) do
          [true, "Table cache hit ratio is correct: #{Float.round(val, 5)}"]
        else
          [false, "Table cache hit ratio is too low: #{Float.round(val, 5)}"]
        end
    end

    [ok, "table_cache_hit", message]
  end

  defp index_cache_hit(repo) do
    index_cache_hit_val = EctoPSQLExtras.cache_hit(repo, format: :raw).rows
    |> Enum.at(0) |> Enum.at(1)

    [ok, message] = case index_cache_hit_val do
      nil ->
        [false, "Index cache hit ratio is not yet reported."]
      %Decimal{} = val ->
        val = Decimal.to_float(val) |> Float.round(6)

        if val >= @index_cache_hit_min_expected do
          [true, "Index cache hit ratio is correct: #{Float.round(val, 5)}"]
        else
          [false, "Index cache hit ratio is too low: #{Float.round(val, 5)}"]
        end
    end

    [ok, "index_cache_hit", message]
  end

  defp unused_indexes(repo) do
    indexes = EctoPSQLExtras.unused_indexes(
      repo,
      format: :raw,
      args: [min_scans: @unused_indexes_max_scans]
    ).rows
    |> Enum.filter(fn(el) ->
      Enum.at(el, 3) >= @unused_indexes_min_size_bytes
    end)

    [ok, message] = case indexes do
      [] ->
        [true, "No unused indexes detected."]
      _ ->
        print_indexes = Enum.map_join(indexes, ", ", fn(el) ->
          "'#{Enum.at(el, 2)}'"
        end)

        [false, "Unused indexes detected: #{print_indexes}"]
    end

    [ok, "unused_indexes", message]
  end

  defp null_indexes(repo) do
    indexes = EctoPSQLExtras.null_indexes(
      repo,
      format: :raw,
      args: [min_relation_size_mb: @null_indexes_min_size_mb]
    ).rows
    |> Enum.filter(fn(el) ->
      null_frac = Enum.at(el, 4)
      |> String.replace("%", "")
      |> Float.parse
      |> elem(0)
      null_frac > @null_min_null_frac_percent
    end)

    [ok, message] = case indexes do
      [] ->
        [true, "No null indexes detected."]
      _ ->
        print_indexes = Enum.map(indexes, fn(el) ->
          "'#{Enum.at(el, 1)}'"
        end) |> Enum.join(", ")

        [false, "Null indexes detected: #{print_indexes}"]
    end

    [ok, "null_indexes", message]
  end

  defp bloat(repo) do
    bloated_objects = EctoPSQLExtras.bloat(
      repo,
      format: :raw
    ).rows
    |> Enum.filter(fn(el) ->
      Enum.at(el, 3) > Decimal.from_float(@bloat_min_value)
    end)

    [ok, message] = case bloated_objects do
      [] ->
        [true, "No bloated tables or indexes detected."]
      _ ->
        print_bloat = Enum.map_join(bloated_objects, ", ", fn(el) ->
          "#{Enum.at(el, 0)} '#{Enum.at(el, 2)}'"
        end)

        [false, "Bloat detected: #{print_bloat}"]
    end

    [ok, "bloat", message]
  end

  defp duplicate_indexes(repo) do
    indexes = EctoPSQLExtras.duplicate_indexes(
      repo,
      format: :raw
    ).rows

    [ok, message] = case indexes do
      [] ->
        [true, "No duplicate indexes detected."]
      _ ->
        print_indexes = Enum.map_join(indexes, ", ", fn(el) ->
          "'#{Enum.at(el, 1)}' - '#{Enum.at(el, 2)}' size #{Enum.at(el, 0)}'"
        end)

        [false, "Duplicate indexes detected: #{print_indexes}"]
    end

    [ok, "duplicate_indexes", message]
  end

  defp outliers(repo) do
    case EctoPSQLExtras.pg_stat_statements_version(repo) do
      nil ->
        [false, "outliers", "Cannot check outliers because 'pg_stat_statements' extension is not enabled."]
      _ ->
        outliers_data(repo)
    end
  end

  defp outliers_data(repo) do
    queries = EctoPSQLExtras.outliers(
      repo,
      format: :raw
    ).rows
    |> Enum.filter(fn(el) ->
      Enum.at(el, 2) > @outliers_min_exec_ratio
    end)

    [ok, message] = case queries do
      [] ->
        [true, "No queries using significant execution ratio detected."]
      _ ->
        print_queries = Enum.map_join(queries, ", ", fn(el) ->
          "'#{Enum.at(el, 0) |> String.slice(0, 20)}...' using #{Enum.at(el, 2)}%"
        end)

        [false, "Queries using significant execution ratio detected: #{print_queries}"]
    end

    [ok, "outliers", message]
  end

  defp ssl_used(repo) do
    if EctoPSQLExtras.ssl_info_enabled(repo) do
      ssl_used_data(repo)
    else
      [false, "ssl_used", "Cannot check connection status because 'ssl_info' extension is not enabled."]
    end
  end

  defp ssl_used_data(repo) do
    %Postgrex.Result{rows: [[ssl_used_result]]} = EctoPSQLExtras.ssl_used(
      repo,
      format: :raw
    )

    [ok, message] = case ssl_used_result do
      true ->
        [true, "Database client is using a secure SSL connection."]
      false ->
        [false, "Database client is using an unencrypted connection."]
    end

    [ok, "ssl_used", message]
  end
end
