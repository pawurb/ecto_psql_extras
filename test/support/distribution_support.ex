defmodule EctoPSQLExtras.DistributionSupport do
  # This module helps to spawn a new node to test
  # distribution. The remote node does not requires
  # EctoPSQLExtras, but requires that the repository
  # exists.
  #
  # Check the "test/support/dummy_app.exs".
  # It requires Elixir 1.12
  def setup_support_project!(filename) do
    hostname = current_hostname!()

    {port, name} = spawn_support_project!(filename)
    :ok = wait_to_start(port)

    os_pid = Port.info(port)[:os_pid]

    System.at_exit(fn _ ->
      {"", 0} = System.cmd("kill", [to_string(os_pid)])
    end)

    [node_name: :"#{name}@#{hostname}", short_name: name, hostname: hostname]
  end

  def current_hostname! do
    unless Node.alive?() do
      raise "for running distribution tests you must start with a node name and cookie"
    end

    [_, hostname] = Node.self() |> Atom.to_string() |> String.split("@")
    hostname
  end

  defp spawn_support_project!(project_file) do
    elixir_path = System.find_executable("elixir")
    cookie = Node.get_cookie()
    short_name = Base.encode16(:crypto.strong_rand_bytes(3), case: :lower)
    script_path = Path.join([__DIR__, "..", "support", project_file])

    unless File.exists?(script_path) do
      raise ArgumentError, "project file does not exist!"
    end

    args = String.split("--sname #{short_name} --no-halt --cookie #{cookie} #{script_path}")

    {Port.open({:spawn_executable, elixir_path}, [:binary, args: args]), short_name}
  end

  defp wait_to_start(port) do
    receive do
      {^port, {:data, "starting app" <> _}} ->
        :ok

      _ ->
        wait_to_start(port)
    end
  end
end
