Code.require_file "support/test_repo.exs", __DIR__

Application.put_env(:ecto_psql_extras, :node_name, Node.self())

Application.put_env(:dummy_app, Dummy.Repo, [url: EctoPSQLExtras.TestRepo.database_url()])

ExUnit.configure(exclude: :distribution)
ExUnit.start()
