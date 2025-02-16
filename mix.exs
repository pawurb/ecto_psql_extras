defmodule EctoPSQLExtras.Mixfile do
  use Mix.Project
  @github_url "https://github.com/pawurb/ecto_psql_extras"
  @version "0.8.6"

  def project do
    [
      app: :ecto_psql_extras,
      version: @version,
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      description: description(),
      deps: deps(),
      package: package(),
      docs: docs()
    ]
  end

  def deps do
    [
      {:table_rex, "~> 3.1.1 or ~> 4.0"},
      {:ecto_sql, "~> 3.7"},
      {:postgrex, "> 0.16.0"},
      {:ex_doc, ">= 0.30.0", only: :dev, runtime: false},
      {:mock, "~> 0.3.0", only: :test}
    ]
  end

  defp description do
    """
    Ecto PostgreSQL database performance insights. Locks, index usage, buffer cache hit ratios, vacuum stats and more.
    """
  end

  defp package do
    [
      maintainers: ["Pawel Urbanek"],
      licenses: ["MIT"],
      links: %{"GitHub" => @github_url}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @github_url,
      extras: ["README.md"]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
