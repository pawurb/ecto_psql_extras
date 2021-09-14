Code.require_file "support/test_repo.exs", __DIR__

nodes = [:"node1@127.0.0.1", :"node2@127.0.0.1"]

EctoPSQLExtras.ClusterSupport.spawn(nodes)
Application.put_env(:ecto_psql_extras, :nodes, nodes)

ExUnit.configure(exclude: :distribution)
ExUnit.start()
