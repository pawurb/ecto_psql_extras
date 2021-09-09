defmodule EctoPSQLExtras.TestRepo do
  use Ecto.Repo, otp_app: :ecto_psql_extras, adapter: Ecto.Adapters.Postgres

  def init(type, opts) do
    opts = [url: database_url()] ++ opts
    opts[:parent] && send(opts[:parent], {__MODULE__, type, opts})
    {:ok, opts}
  end

  defp database_url do
    postgres_url = System.get_env("POSTGRES_URL")

    if postgres_url do
      "ecto://#{postgres_url}/#{System.fetch_env!("POSTGRES_DB")}"
    else
      "ecto://#{System.fetch_env!("POSTGRES_USER")}:#{System.fetch_env!("POSTGRES_PASSWORD")}@#{System.fetch_env!("POSTGRES_HOST")}:#{System.fetch_env!("POSTGRES_PORT")}/#{System.fetch_env!("POSTGRES_DB")}"
    end
  end
end

EctoPSQLExtras.TestRepo.start_link()
