# This file is a self contained application used in
# distribution tests. It requires Elixir 1.12.

Mix.install(ecto_sql: "~> 3.4", postgrex: ">= 0.15.7")

postgres_url = System.get_env("POSTGRES_URL")

# Uses the same from the main app.
db_url =
  if postgres_url do
    "ecto://#{postgres_url}/#{System.fetch_env!("POSTGRES_DB")}"
  else
    "ecto://#{System.fetch_env!("POSTGRES_USER")}:#{System.fetch_env!("POSTGRES_PASSWORD")}@#{System.fetch_env!("POSTGRES_HOST")}:#{System.fetch_env!("POSTGRES_PORT")}/#{System.fetch_env!("POSTGRES_DB")}"
  end

Application.put_env(:dummy_app, Dummy.Repo, url: db_url)

defmodule Dummy.Repo do
  use Ecto.Repo, otp_app: :dummy_app, adapter: Ecto.Adapters.Postgres
end

_ = Ecto.Adapters.Postgres.storage_up(Dummy.Repo.config())

IO.puts("starting app")

children = [
  Dummy.Repo
]

Task.async(fn ->
  {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)

  Process.sleep(:infinity)
end) |> Task.await(:infinity)
