defmodule EctoPSQLExtrasTest do
  use ExUnit.Case, async: true

  import EctoPSQLExtras
  import ExUnit.CaptureIO
  import ExUnit.CaptureLog
  alias EctoPSQLExtras.TestRepo

  @optional_queries %{
    calls: EctoPSQLExtras.Calls,
    calls_legacy: EctoPSQLExtras.CallsLegacy,
    outliers: EctoPSQLExtras.Outliers,
    outliers_legacy: EctoPSQLExtras.OutliersLegacy
  }

  @skip_queries [:kill_all]

  test "all queries define info" do
    for pair <- Map.merge(queries(), @optional_queries) do
      {name, module} = pair
      assert is_atom(name)

      info = module.info()
      assert info.title

      for column <- info.columns do
        assert column.name
        assert column.type
      end

      for {order_by, dir} <- info[:order_by] || [] do
        assert dir in [:asc, :desc]
        assert Enum.find(info.columns, &(&1.name == order_by))
      end
    end
  end

  defmodule Repo do
    def query!(_, _, _), do: %{rows: Process.get(Repo) || raise "no query result"}
  end

  describe "pg_stat_statements queries" do
    test "are not included without repo" do
      queries = queries(nil)
      refute Map.has_key?(queries, :calls)
      refute Map.has_key?(queries, :outliers)
    end

    test "are not included on repo without pg_stat_statements" do
      Process.put(Repo, [[]])
      queries = queries(Repo)
      refute Map.has_key?(queries, :calls)
      refute Map.has_key?(queries, :outliers)

      Process.put(Repo, [[nil]])
      queries = queries(Repo)
      refute Map.has_key?(queries, :calls)
      refute Map.has_key?(queries, :outliers)
    end

    test "includes legacy queries on early versions" do
      Process.put(Repo, [["1.2.0"]])
      queries = queries(Repo)
      assert {:calls, EctoPSQLExtras.CallsLegacy} in queries
      assert {:outliers, EctoPSQLExtras.OutliersLegacy} in queries
    end

    test "includes recent queries on later versions" do
      Process.put(Repo, [["1.9.0"]])
      queries = queries(Repo)
      assert {:calls, EctoPSQLExtras.Calls} in queries
      assert {:outliers, EctoPSQLExtras.Outliers} in queries

      Process.put(Repo, [["2.1.0"]])
      queries = queries(Repo)
      assert {:calls, EctoPSQLExtras.Calls} in queries
      assert {:outliers, EctoPSQLExtras.Outliers} in queries
    end
  end

  test "format bytes" do
    assert format_value({0, :bytes}) == "0 bytes"
    assert format_value({1000, :bytes}) == "1000 bytes"
    assert format_value({1024, :bytes}) == "1.0 KB"
    assert format_value({1200, :bytes}) == "1.2 KB"
    assert format_value({1024 * 1024, :bytes}) == "1.0 MB"
    assert format_value({1024 * 1200, :bytes}) == "1.2 MB"
    assert format_value({1024 * 1024 * 1024, :bytes}) == "1.0 GB"
    assert format_value({1024 * 1024 * 1200, :bytes}) == "1.2 GB"
    assert format_value({1024 * 1024 * 1024 * 1024, :bytes}) == "1.0 TB"
    assert format_value({1024 * 1024 * 1024 * 1024 * 1024, :bytes}) == "1024.0 TB"
  end

  test "format structs" do
    assert format_value({Decimal.new("1.23"), :d}) ==
             "1.23"

    assert format_value({%Postgrex.Interval{secs: 0}, :i}) ==
             "0 seconds"

    assert format_value({%Postgrex.Interval{months: 2, days: 2, secs: 1, microsecs: 654_321}, :i}) ==
             "2 months, 2 days, 1.654321 seconds"
  end

  test "format string" do
    assert format_value({"Multiline \n\nstring", :string}) == "Multiline string"
  end

  describe "database interaction" do
    setup do
      start_supervised!(EctoPSQLExtras.TestRepo)
      EctoPSQLExtras.TestRepo.query!("CREATE EXTENSION IF NOT EXISTS pg_stat_statements;", [], log: false)
      :ok
    end

    test "run queries by param" do
      for query <- Enum.reduce((queries(TestRepo) |> Map.to_list), [], fn(el, acc) ->
        case elem(el, 0) in @skip_queries do
          true ->
            acc
          false ->
            [elem(el, 0) | acc]
        end
      end) do
        assert(length(
          EctoPSQLExtras.query(
            query,
            TestRepo,
            [format: :raw]
          ).columns
        ) > 0)
      end
    end

    test "provide custom param" do
      assert(length(
        EctoPSQLExtras.long_running_queries(
          TestRepo,
          [format: :raw, args: [threshold: '1 second']]
        ).columns
      ) > 0)

      assert(length(
        EctoPSQLExtras.query(
          :long_running_queries,
          TestRepo,
          [format: :raw, args: [threshold: '200 milliseconds']]
        ).columns
      ) > 0)
    end

    test "test legacy API" do
      warning = capture_io(:stderr, fn ->
        columns = EctoPSQLExtras.long_running_queries(TestRepo, :raw).columns
        assert length(columns)  > 0
      end)

      assert warning =~ "This API is deprecated. Please pass format value as a keyword list: `format: :raw`"
    end

    test "test query_opts allows for logging" do
      logs = capture_log(fn ->
        EctoPSQLExtras.long_running_queries(TestRepo, format: :raw, query_opts: [log: true])
      end)
      assert logs =~ "ECTO_PSQL_EXTRAS: All queries longer than the threshold by descending duration"
    end

    test "run queries by method" do
      for query <- Enum.reduce((queries(TestRepo) |> Map.to_list), [], fn(el, acc) ->
        case elem(el, 0) in @skip_queries do
          true ->
            acc
          false ->
            [elem(el, 0) | acc]
        end
      end) do
        assert(length(
          apply(
            EctoPSQLExtras,
            query,
            [TestRepo, [format: :raw]]
          ).columns
        ) > 0)
      end
    end
  end

  describe "integration with a remote node" do
    setup context do
      if context[:distribution] do
        start_supervised!(Dummy.Repo)
        # Node names are configured in test_helper.exs
        node_name = Application.fetch_env!(:ecto_psql_extras, :node_name)

        {:ok, node_name: node_name}
      else
        :ok
      end
    end

    @tag :distribution
    test "run queries by param", %{node_name: node_name} do
      assert Node.connect(node_name)

      for query_name <- Map.keys(queries()), query_name not in @skip_queries do
        assert EctoPSQLExtras.query(query_name, {Dummy.Repo, node_name}, format: :raw).columns !=
                 []
      end
    end

    @tag :distribution
    test "provide custom param", %{node_name: node_name} do
      assert Node.connect(node_name)

      assert EctoPSQLExtras.long_running_queries({Dummy.Repo, node_name},
               format: :raw,
               args: [threshold: '1 second']
             ).columns != []

      assert EctoPSQLExtras.query(:long_running_queries, {Dummy.Repo, node_name},
               format: :raw,
               args: [threshold: '200 milliseconds']
             ).columns != []
    end

    @tag :distribution
    test "fails when repo is not available", %{node_name: node_name} do
      assert Node.connect(node_name)

      assert_raise RuntimeError, "repository is not defined on remote node", fn ->
        EctoPSQLExtras.long_running_queries({Dummy.InvalidRepo, node_name},
          format: :raw,
          args: [threshold: '1 second']
        )
      end
    end

    test "fails when disconnected" do
      node_name = :"idontexist@127.0.0.1"

      assert_raise RuntimeError,
                   "cannot send query to remote node #{inspect(node_name)}. Reason: :nodedown",
                   fn ->
                     EctoPSQLExtras.long_running_queries({Dummy.Repo, node_name},
                       format: :raw,
                       args: [threshold: '1 second']
                     )
                   end
    end
  end
end
