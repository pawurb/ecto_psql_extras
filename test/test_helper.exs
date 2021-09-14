Code.require_file "support/test_repo.exs", __DIR__

node_name = :"primary@127.0.0.1"

:net_kernel.start([node_name])
Application.put_env(:ecto_psql_extras, :node_name, node_name)

postgres_url = System.get_env("POSTGRES_URL")

# Uses the same from the main app.
db_url =
  if postgres_url do
    "ecto://#{postgres_url}/#{System.fetch_env!("POSTGRES_DB")}"
  else
    "ecto://#{System.fetch_env!("POSTGRES_USER")}:#{System.fetch_env!("POSTGRES_PASSWORD")}@#{System.fetch_env!("POSTGRES_HOST")}:#{System.fetch_env!("POSTGRES_PORT")}/#{System.fetch_env!("POSTGRES_DB")}"
  end

Application.put_env(:dummy_app, Dummy.Repo, [url: db_url])

ExUnit.configure(exclude: :distribution)
ExUnit.start()
