defmodule EctoPSQLExtras.MissingFkIndexesLogic do
  @moduledoc """
  Detect missing foreign key indexes
  """

  require Logger

  def run(repo, table_name \\ nil) do
    all_indexes = EctoPSQLExtras.indexes(repo, format: :raw).rows

    all_tables =
      EctoPSQLExtras.table_size(repo, format: :raw).rows
      |> Enum.map(fn [_, table_name, _] -> table_name end)

    tables =
      if table_name do
        [to_string(table_name)]
      else
        all_tables
      end

    rows =
      Enum.reduce(tables, [], fn table, agg ->
        indexed_columns =
          all_indexes
          |> Enum.filter(fn [_, _, index_table_name, _] -> index_table_name == table end)
          |> Enum.map(fn [_, _, _, column_name] ->
            column_name
            |> String.split(",")
            |> List.first()
          end)

        fk_columns =
          EctoPSQLExtras.table_schema(repo, args: [table_name: table], format: :raw).rows
          |> Enum.map(fn [column_name, _, _, _, _] -> column_name end)
          |> Enum.filter(fn column_name ->
            EctoPSQLExtras.DetectFkColumn.call(column_name, all_tables)
          end)

        missing_indexes =
          Enum.reduce(fk_columns, agg, fn column_name, agg ->
            if !Enum.member?(indexed_columns, column_name) do
              [[table, column_name] | agg]
            else
              agg
            end
          end)

        missing_indexes
      end)

    %{
      rows: rows,
      columns: ["table", "column_name"]
    }
  end
end
