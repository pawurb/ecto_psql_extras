defmodule EctoPSQLExtras.Mixfile do
  use Mix.Project
  @github_url "https://github.com/pawurb/ecto_psql_extras"
  @version "0.1.3"

  def project do
    [
      app: :ecto_psql_extras,
      version: @version,
      elixir: "~> 1.5",
      escript: [main_module: EctoPSQLExtras],
      description: description(),
      deps: deps(),
      package: package(),
      source_url: @github_url
    ]
  end

  def deps() do
    [
      { :table_rex, "~> 3.0.0" },
      { :ecto, "~> 3.4" },
      { :ex_doc, ">= 0.0.0", only: :dev, runtime: false }
    ]
  end

  defp description() do
    """
Ecto PostgreSQL database performance insights. Locks, index usage, buffer cache hit ratios, vacuum stats and more.
"""
  end

  defp package() do
    [
      files: ["lib/ecto_psql_extras.ex", "mix.exs", "lib/queries/*"],
      maintainers: ["Pawel Urbanek"],
      licenses: ["MIT"],
      links: %{ "GitHub" => @github_url }
    ]
  end
end
