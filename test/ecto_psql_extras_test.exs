defmodule EctoPSQLExtrasTest do
  use ExUnit.Case, async: true

  import EctoPSQLExtras
  alias EctoPSQLExtras.TestRepo

  @optional_queries %{
    calls: EctoPSQLExtras.Calls,
    calls_legacy: EctoPSQLExtras.CallsLegacy,
    outliers: EctoPSQLExtras.Outliers,
    outliers_legacy: EctoPSQLExtras.OutliersLegacy
  }

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
    def query!(_), do: %{rows: Process.get(Repo) || raise "no query result"}
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
    @skip_queries [:kill_all]

    test "run queries by param" do
      for query <- Enum.reduce((queries() |> Map.to_list), [], fn(el, acc) ->
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

    test "run queries by method" do
      for query <- Enum.reduce((queries() |> Map.to_list), [], fn(el, acc) ->
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
end
