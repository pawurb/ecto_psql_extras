defmodule EctoPSQLExtras.TableForeignKeys do
  @behaviour EctoPSQLExtras

  def info do
    %{
      title: "Foreign keys info",
      columns: [
        %{name: :table_name, type: :string},
        %{name: :constraint_name, type: :string},
        %{name: :column_name, type: :string},
        %{name: :foreign_table_name, type: :string},
        %{name: :foreign_column_name, type: :string}
      ]
    }
  end

  def query(args \\ []) do
    if args[:table_name] do
      """
      /* ECTO_PSQL_EXTRAS: Foreign keys info for a specific table */

      SELECT
      conrelid::regclass::text AS table_name,
      conname AS constraint_name,
      a.attname AS column_name,
      confrelid::regclass::text AS foreign_table_name,
      af.attname AS foreign_column_name
      FROM
      pg_constraint AS c
      JOIN
      pg_attribute AS a ON a.attnum = ANY(c.conkey) AND a.attrelid = c.conrelid
      JOIN
      pg_attribute AS af ON af.attnum = ANY(c.confkey) AND af.attrelid = c.confrelid
      WHERE
      c.contype = 'f'
      AND c.conrelid = '<%= table_name %>'::regclass;
      """
      |> EEx.eval_string(args)
    else
      """
      /* ECTO_PSQL_EXTRAS: Foreign keys info for all tables */

      SELECT
      conrelid::regclass::text AS table_name,
      conname AS constraint_name,
      a.attname AS column_name,
      confrelid::regclass::text AS foreign_table_name,
      af.attname AS foreign_column_name
      FROM
      pg_constraint AS c
      JOIN
      pg_attribute AS a ON a.attnum = ANY(c.conkey) AND a.attrelid = c.conrelid
      JOIN
      pg_attribute AS af ON af.attnum = ANY(c.confkey) AND af.attrelid = c.confrelid
      WHERE
      c.contype = 'f';
      """
    end
  end
end
