Code.require_file "support/test_repo.exs", __DIR__

node_name = :"primary@127.0.0.1"

:net_kernel.start([node_name])
Application.put_env(:ecto_psql_extras, :node_name, node_name)

Application.put_env(:dummy_app, Dummy.Repo, [url: EctoPSQLExtras.TestRepo.database_url()])

ExUnit.configure(exclude: :distribution)
ExUnit.start()
