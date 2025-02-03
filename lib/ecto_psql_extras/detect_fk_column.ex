defmodule EctoPSQLExtras.DetectFkColumn do
  @plural_rules [
    {~r/s$/i, "s"},
    {~r/^(ax|test)is$/i, "\\1es"},
    {~r/(octop|vir)us$/i, "\\1i"},
    {~r/(alias|status)$/i, "\\1es"},
    {~r/(bu)s$/i, "\\1ses"},
    {~r/(buffal|tomat)o$/i, "\\1oes"},
    {~r/([ti])um$/i, "\\1a"},
    {~r/sis$/i, "ses"},
    {~r/(?:([^f])fe|([lr])f)$/i, "\\1\\2ves"},
    {~r/([^aeiouy]|qu)y$/i, "\\1ies"},
    {~r/(x|ch|ss|sh)$/i, "\\1es"},
    {~r/(matr|vert|ind)(?:ix|ex)$/i, "\\1ices"},
    {~r/^(m|l)ouse$/i, "\\1ice"},
    {~r/^(ox)$/i, "\\1en"},
    {~r/(quiz)$/i, "\\1zes"}
  ]

  @irregular %{
    "person" => "people",
    "man" => "men",
    "child" => "children",
    "sex" => "sexes",
    "move" => "moves",
    "zombie" => "zombies"
  }

  @uncountable ~w(equipment information rice money species series fish sheep jeans police)

  def call(column_name, tables) do
    if String.ends_with?(column_name, "_id") do
      table_name =
        column_name
        |> String.split("_")
        |> List.first()
        |> pluralize()

      Enum.member?(tables, table_name)
    else
      false
    end
  end

  def pluralize(word) do
    word_lower = String.downcase(word)

    cond do
      Enum.member?(@uncountable, word_lower) ->
        word

      Map.has_key?(@irregular, word) ->
        @irregular[word]

      Map.values(@irregular) |> Enum.member?(word) ->
        @irregular |> Enum.find(fn {_, v} -> v == word end) |> elem(0)

      true ->
        apply_plural_rules(word)
    end
  end

  defp apply_plural_rules(word) do
    transformed_word =
      Enum.reduce(Enum.reverse(@plural_rules), word, fn {rule, replacement}, acc ->
        if Regex.match?(rule, acc) do
          Regex.replace(rule, acc, replacement)
        else
          acc
        end
      end)

    if transformed_word == word do
      word <> "s"
    else
      transformed_word
    end
  end
end
