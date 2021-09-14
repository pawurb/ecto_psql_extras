defmodule EctoPSQLExtras.TestRepo do
  use Ecto.Repo, otp_app: :ecto_psql_extras, adapter: Ecto.Adapters.Postgres

  def init(type, opts) do
    opts = [url: database_url()] ++ opts
    opts[:parent] && send(opts[:parent], {__MODULE__, type, opts})
    {:ok, opts}
  end

  def database_url do
    postgres_url = System.get_env("POSTGRES_URL")

    if postgres_url do
      "ecto://#{postgres_url}/#{fetch_env!("POSTGRES_DB")}"
    else
      "ecto://#{fetch_env!("POSTGRES_USER")}:#{fetch_env!("POSTGRES_PASSWORD")}@#{fetch_env!("POSTGRES_HOST")}:#{fetch_env!("POSTGRES_PORT")}/#{fetch_env!("POSTGRES_DB")}"
    end
  end

  # Only needed because we still support Elixir below 1.9
  defp fetch_env!(name) do
    System.get_env(name) ||
      raise ArgumentError,
            "could not fetch environment variable #{inspect(name)} because it is not set"
  end
end
