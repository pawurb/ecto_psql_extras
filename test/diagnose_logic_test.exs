defmodule DiagnoseLogicTest do
  use ExUnit.Case, async: false
  alias EctoPSQLExtras.TestRepo
  import Mock

  setup do
    start_supervised!(TestRepo)
    EctoPSQLExtras.TestRepo.query!("CREATE EXTENSION IF NOT EXISTS pg_stat_statements;", [], log: false)
    EctoPSQLExtras.TestRepo.query!("CREATE EXTENSION IF NOT EXISTS sslinfo;", [], log: false)
    :ok
  end

  test_with_mock "it works", EctoPSQLExtras, [:passthrough], [
    unused_indexes: fn(_repo, _opts) ->
      %Postgrex.Result{
        columns: ["schema", "table", "index", "index_size", "index_scans"],
        command: :select,
        connection_id: 28521,
        messages: [],
        num_rows: 0,
        rows: [
          ["public", "public.plans", "index_plans_on_payer_id_1", 16000000, 0],
          ["public", "public.feedbacks", "index_feedbacks_on_target_id", 8000, 1],
          ["public", "public.channels", "index_channels_on_slack_id", 1000001, 7]
        ]
      }
    end,
    null_indexes: fn(_repo, _opts) ->
      %Postgrex.Result{
        columns: ["oid", "index", "index_size", "unique", "indexed_column", "null_frac", "expected_saving"],
        command: :select,
        connection_id: 28521,
        messages: [],
        num_rows: 0,
        rows: [
          ["123", "index_plans_on_payer_id", "16 MB", true, "00.00%", "0 kb"],
          ["321", "index_feedbacks_on_target_id", "80 kB", false, "97.00%", "77 kb"],
          ["231", "index_channels_on_slack_id", "56 MB", true, "49.99%", "28 MB"]
        ]
      }
    end,
    bloat: fn(_repo, _opts) ->
      %Postgrex.Result{
        columns: ["type", "schemaname", "object_name", "bloat", "waste"],
        command: :select,
        connection_id: 28521,
        messages: [],
        num_rows: 0,
        rows: [
          ["table", "public", "bloated_table_1", Decimal.from_float(11.2), 98000],
          ["table", "public", "less_bloated_table_1", Decimal.from_float(1.4), 800]
        ]
      }
    end,
    duplicate_indexes: fn(_repo, _opts) ->
      %Postgrex.Result{
        columns: ["size", "idx1", "idx2", "idx3", "idx4"],
        command: :select,
        connection_id: 28521,
        messages: [],
        num_rows: 0,
        rows: [
          ["128 kb", "users_pkey", "index_users_id", nil, nil]
        ]
      }
    end,
    outliers: fn(_repo, _opts) ->
      %Postgrex.Result{
        columns: ["query", "exec_time", "prop_exec_time", "ncalls", "sync_io_time"],
        command: :select,
        connection_id: 28521,
        messages: [],
        num_rows: 0,
        rows: [
          [
            "SELECT * FROM users WHERE users.age > 20 AND users.height > 160",
            %Postgrex.Interval{days: 0, microsecs: 789382, months: 0, secs: 0},
            72.2,
            123098,
            %Postgrex.Interval{days: 0, microsecs: 3219, months: 0, secs: 0},
          ],
          [
            "SELECT * FROM products",
            %Postgrex.Interval{days: 0, microsecs: 17668, months: 0, secs: 0},
            12.7,
            211877,
            %Postgrex.Interval{days: 0, microsecs: 97668, months: 0, secs: 0},
          ]
        ]
      }
    end
  ] do
    EctoPSQLExtras.diagnose(EctoPSQLExtras.TestRepo)

    result = EctoPSQLExtras.DiagnoseLogic.run(EctoPSQLExtras.TestRepo)

    assert length(result.columns) == 3
    assert Enum.at(Enum.at(result.rows, 0), 1) == "table_cache_hit"
  end
end
