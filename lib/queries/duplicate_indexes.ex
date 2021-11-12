defmodule EctoPSQLExtras.DuplicateIndexes do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "Multiple indexes that have the same set of columns, same opclass, expression and predicate.",
      index: 7,
      columns: [
        %{name: :size, type: :string},
        %{name: :idx1, type: :string},
        %{name: :idx2, type: :string},
        %{name: :idx3, type: :string},
        %{name: :idx4, type: :string}
      ]
    }
  end

  def query(args \\ []) do
    """
    /* ECTO_PSQL_EXTRAS: Multiple indexes that have the same set of columns, same opclass, expression and predicate */

    SELECT pg_size_pretty(sum(pg_relation_size(idx))::bigint) as size,
       (array_agg(idx))[1] as idx1, (array_agg(idx))[2] as idx2,
       (array_agg(idx))[3] as idx3, (array_agg(idx))[4] as idx4
    FROM (
        SELECT indexrelid::regclass as idx, (indrelid::text ||E'\n'|| indclass::text ||E'\n'|| indkey::text ||E'\n'||
        coalesce(indexprs::text,'')||E'\n' || coalesce(indpred::text,'')) as key
      FROM pg_index) sub
    GROUP BY key HAVING count(*)>1
    ORDER BY sum(pg_relation_size(idx)) DESC;
    """ |> EEx.eval_string(args)
  end
end
