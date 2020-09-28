if match?({:module, _}, Code.ensure_compiled(Phoenix.LiveDashboard)) do
  defmodule Phoenix.LiveDashboard.Pages.PSQLStatsPage do
    @moduledoc false
    use Phoenix.LiveDashboard.PageBuilder

    @menu_text "PSQL Stats"

    @impl true
    def init(%{repo: repo}) do
      {:ok, %{repo: repo}, process: repo}
    end

    @impl true
    def mount(_params, %{repo: repo}, socket) do
      {:ok, assign(socket, repo: repo)}
    end

    @impl true
    def menu_link(%{repo: repo}, capabilities) do
      if repo in capabilities.processes do
        {:ok, @menu_text}
      else
        {:disabled, @menu_text}
      end
    end

    @impl true
    def render_page(assigns) do
      nav_bar(items: tabs(assigns))
    end

    @tables [
      :cache_hit,
      :index_cache_hit,
      :table_cache_hit,
      :index_usage,
      :locks,
      :all_locks,
      :outliers,
      :calls,
      :blocking,
      :total_index_size,
      :index_size,
      :table_size,
      :table_indexes_size,
      :total_table_size,
      :unused_indexes,
      :seq_scans,
      :long_running_queries,
      :records_rank,
      :bloat,
      :vacuum_stats
    ]
    defp tabs(%{repo: repo}) do
      for table_name <- @tables do
        {table_name,
         name: Phoenix.Naming.humanize(table_name), render: render_table(table_name, repo)}
      end
    end

    defp render_table(table, repo) do
      table(
        columns: table_columns(table),
        id: :table_id,
        # row_attrs: table_row_attrs(table),
        row_fetcher: row_fetcher(table, repo),
        title: Phoenix.Naming.humanize(table)
      )
    end

    defp table_columns(:cache_hit) do
      [%{field: :name, sortable: :asc}, %{field: :ratio, sortable: :desc}]
    end

    defp table_columns(:index_cache_hit) do
      [
        %{field: :name, sortable: :asc},
        %{field: :buffer_hits, sortable: :desc},
        %{field: :block_reads, sortable: :desc},
        %{field: :total_read, sortable: :desc},
        %{field: :ratio, sortable: :desc}
      ]
    end

    defp table_columns(:table_cache_hit) do
      [
        %{field: :name, sortable: :asc},
        %{field: :buffer_hits, sortable: :desc},
        %{field: :block_reads, sortable: :desc},
        %{field: :total_read, sortable: :desc},
        %{field: :ratio, sortable: :desc}
      ]
    end

    defp table_columns(:index_usage) do
      [
        %{field: :relname, sortable: :desc},
        %{field: :percent_of_times_index_used, sortable: :desc},
        %{field: :rows_in_table, sortable: :desc}
      ]
    end

    defp table_columns(:locks) do
      [
        %{field: :procpid, sortable: :desc},
        %{field: :relname, sortable: :desc},
        %{field: :transactionid, sortable: :desc},
        %{field: :granted, sortable: :desc},
        %{field: :query_snippet, sortable: :desc},
        %{field: :mode, sortable: :desc},
        %{field: :age, sortable: :desc}
      ]
    end

    defp table_columns(:all_locks) do
      [
        %{field: :pid, sortable: :desc},
        %{field: :relname, sortable: :desc},
        %{field: :transactionid, sortable: :desc},
        %{field: :granted, sortable: :desc},
        %{field: :query_snippet, sortable: :desc},
        %{field: :mode, sortable: :desc},
        %{field: :age, sortable: :desc}
      ]
    end

    defp table_columns(table) when table in [:outliers, :calls] do
      [
        %{field: :qry, sortable: :desc},
        %{field: :exec_time, sortable: :desc},
        %{field: :prop_exec_time, sortable: :desc},
        %{field: :ncalls, sortable: :desc},
        %{field: :sync_io_time, sortable: :desc}
      ]
    end

    defp table_columns(:blocking) do
      [
        %{field: :blocked_pid, sortable: :desc},
        %{field: :blocking_statement, sortable: :desc},
        %{field: :blocking_duration, sortable: :desc},
        %{field: :blocking_pid, sortable: :desc},
        %{field: :blocked_statement, sortable: :desc},
        %{field: :blocked_duration, sortable: :desc}
      ]
    end

    defp table_columns(:total_index_size) do
      [
        %{field: :size, sortable: :desc}
      ]
    end

    defp table_columns(table)
         when table in [
                :index_size,
                :index_size,
                :total_indexes_size,
                :table_size,
                :total_table_size
              ] do
      [
        %{field: :name, sortable: :asc},
        %{field: :size, sortable: :desc}
      ]
    end

    defp table_columns(:table_indexes_size) do
      [
        %{field: :table, sortable: :desc},
        %{field: :size, sortable: :desc}
      ]
    end

    defp table_columns(:unused_indexes) do
      [
        %{field: :table, sortable: :desc},
        %{field: :index, sortable: :desc},
        %{field: :index_size, sortable: :desc},
        %{field: :index_scans, sortable: :desc}
      ]
    end

    defp table_columns(:seq_scans) do
      [
        %{field: :name, sortable: :asc},
        %{field: :count, sortable: :desc}
      ]
    end

    defp table_columns(:long_running_queries) do
      [
        %{field: :pid, sortable: :desc},
        %{field: :duration, sortable: :desc},
        %{field: :query, sortable: :desc}
      ]
    end

    defp table_columns(:records_rank) do
      [
        %{field: :name, sortable: :asc},
        %{field: :estimated_count, sortable: :desc}
      ]
    end

    defp table_columns(:bloat) do
      [
        %{field: :type, sortable: :desc},
        %{field: :schemaname, sortable: :desc},
        %{field: :object_name, sortable: :desc},
        %{field: :bloat, sortable: :desc},
        %{field: :waste, sortable: :desc}
      ]
    end

    defp table_columns(:vacuum_stats) do
      [
        %{field: :schema, sortable: :desc},
        %{field: :table, sortable: :desc},
        %{field: :last_vacuum, sortable: :desc},
        %{field: :last_autovacuum, sortable: :desc},
        %{field: :rowcount, sortable: :desc},
        %{field: :dead_rowcount, sortable: :desc},
        %{field: :autovacuum_threshold, sortable: :desc},
        %{field: :expect_autovacuum, sortable: :desc}
      ]
    end

    defp row_fetcher(name, repo) do
      fn params, node ->
        :rpc.call(node, EctoPSQLExtras, :query, [name, repo, :raw])
        |> calc_rows(params)
      end
    end

    defp calc_rows(%Postgrex.Result{} = result, params) do
      %{search: _search, sort_by: sort_by, sort_dir: sort_dir, limit: limit} = params
      sorter = if sort_dir == :asc, do: &<=/2, else: &>=/2
      %{columns: columns, rows: rows} = result

      rows =
        rows
        |> Enum.map(&Enum.zip(columns, &1))
        |> Enum.map(fn row ->
          Map.new(row, fn {key, value} -> {String.to_atom(key), convert_value(value)} end)
        end)

      count = length(rows)
      rows = rows |> Enum.sort_by(&Map.fetch!(&1, sort_by), sorter) |> Enum.take(limit)
      {rows, count}
    end

    defp convert_value(%Decimal{} = decimal) do
      Decimal.to_float(decimal)
    end

    defp convert_value(value) do
      value
    end
  end
end
