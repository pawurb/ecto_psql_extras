defmodule Dummy.Repo do
  use Ecto.Repo, otp_app: :dummy_app, adapter: Ecto.Adapters.Postgres
end

defmodule EctoPSQLExtras.ClusterSupport do
  # This function helps to spawn new nodes in the
  # current machine. It was based on Phoenix PubSub.
  # https://github.com/phoenixframework/phoenix_pubsub/blob/dac31fa31f52a2e4c61f8a246e4442621076513b/test/support/cluster.ex
  def spawn(nodes) do
    # Turn node into a distributed node with the given long name
    :net_kernel.start([:"primary@127.0.0.1"])

    # Allow spawned nodes to fetch all code from this node
    :erl_boot_server.start([])
    allow_boot(to_charlist("127.0.0.1"))

    nodes
    |> Enum.map(&Task.async(fn -> spawn_node(&1) end))
    |> Enum.map(&Task.await(&1, 30_000))
  end

  defp spawn_node(node_host) do
    {:ok, node} = :slave.start(to_charlist("127.0.0.1"), node_name(node_host), inet_loader_args())

    add_code_paths(node)
    transfer_dummy_repo(node)
    transfer_configuration(node)
    ensure_applications_started(node)
    start_remote_repo(node)

    {:ok, node}
  end

  defp rpc(node, module, function, args) do
    :rpc.block_call(node, module, function, args)
  end

  defp inet_loader_args do
    to_charlist("-loader inet -hosts 127.0.0.1 -setcookie #{:erlang.get_cookie()}")
  end

  defp allow_boot(host) do
    {:ok, ipv4} = :inet.parse_ipv4_address(host)
    :erl_boot_server.add_slave(ipv4)
  end

  defp add_code_paths(node) do
    paths_without_self =
      Enum.reject(:code.get_path(), fn path ->
        to_string(path) |> String.match?(~r/lib\/ecto_psql_extras\/(ebin|consolidated)$/)
      end)

    rpc(node, :code, :add_paths, [paths_without_self])
  end

  defp transfer_configuration(node) do
    for {app_name, _, _} <- Application.loaded_applications() do
      for {key, val} <- Application.get_all_env(app_name) do
        rpc(node, Application, :put_env, [app_name, key, val])
      end
    end

    postgres_url = System.get_env("POSTGRES_URL")

    # Uses the same from the main app.
    db_url =
      if postgres_url do
        "ecto://#{postgres_url}/#{System.fetch_env!("POSTGRES_DB")}"
      else
        "ecto://#{System.fetch_env!("POSTGRES_USER")}:#{System.fetch_env!("POSTGRES_PASSWORD")}@#{System.fetch_env!("POSTGRES_HOST")}:#{System.fetch_env!("POSTGRES_PORT")}/#{System.fetch_env!("POSTGRES_DB")}"
      end

    rpc(node, Application, :put_env, [:dummy_app, Dummy.Repo, [url: db_url]])
  end

  defp transfer_dummy_repo(node) do
    {module, binary, filename} = :code.get_object_code(Dummy.Repo)

    rpc(node, :code, :load_binary, [module, filename, binary])
  end

  defp ensure_applications_started(node) do
    rpc(node, Application, :ensure_all_started, [:mix])
    rpc(node, Mix, :env, [Mix.env()])

    for {app_name, _, _} <- Application.loaded_applications(), app_name != :ecto_psql_extras do
      rpc(node, Application, :ensure_all_started, [app_name])
    end
  end

  defp start_remote_repo(node) do
    args = [
      [Dummy.Repo],
      [strategy: :one_for_one]
    ]

    rpc(node, Supervisor, :start_link, args)
  end

  defp node_name(node_host) do
    node_host
    |> to_string
    |> String.split("@")
    |> Enum.at(0)
    |> String.to_atom()
  end
end
