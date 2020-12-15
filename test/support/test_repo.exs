defmodule EctoPSQLExtras.TestRepo do
  use Ecto.Repo, otp_app: :ecto_psql_extras, adapter: Ecto.Adapters.Postgres

  def init(type, opts) do
    database_url = "ecto://#{System.get_env("POSTGRES_USER")}:#{System.get_env("POSTGRES_PASSWORD")}@#{System.get_env("POSTGRES_HOST")}:#{System.get_env("POSTGRES_PORT")}/#{System.get_env("POSTGRES_DB")}"
    opts = [url: database_url] ++ opts
    opts[:parent] && send(opts[:parent], {__MODULE__, type, opts})
    {:ok, opts}
  end
end

EctoPSQLExtras.TestRepo.start_link()
