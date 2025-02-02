defmodule EctoPSQLExtras.TestRepo do
  use Ecto.Repo, otp_app: :ecto_psql_extras, adapter: Ecto.Adapters.Postgres

  @ports_mapping %{
    "12" => "5432",
    "13" => "5433",
    "14" => "5434",
    "15" => "5435",
    "16" => "5436",
    "17" => "5437"
  }

  def init(type, opts) do
    opts = [url: database_url()] ++ opts
    opts[:parent] && send(opts[:parent], {__MODULE__, type, opts})
    {:ok, opts}
  end

  def database_url do
    postgres_url = System.get_env("DATABASE_URL")

    if postgres_url do
      postgres_url
    else
      user = System.get_env("POSTGRES_USER") || "postgres"
      password = System.get_env("POSTGRES_PASSWORD") || "secret"
      host = System.get_env("POSTGRES_HOST") || "localhost"
      db_name = System.get_env("POSTGRES_DB") || "ecto-psql-extras-test"

      port = Map.get(@ports_mapping, System.get_env("PG_VERSION"), "5432")

      "ecto://#{user}:#{password}@#{host}:#{port}/#{db_name}"
    end
  end
end
