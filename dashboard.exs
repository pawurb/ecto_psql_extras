# iex -S mix run dashboard.exs
Logger.configure(level: :debug)

# Configures the endpoint
Application.put_env(:phoenix_live_dashboard, DemoWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Hu4qQN3iKzTV4fJxhorPQlA/osH9fAMtbtjVS58PFgfw3ja5Z18Q/WSNR9wP4OfW",
  live_view: [signing_salt: "hMegieSe"],
  http: [port: System.get_env("PORT") || 4000],
  debug_errors: true,
  check_origin: false,
  pubsub_server: Demo.PubSub,
  # watchers: [
  #   node: [
  #     "node_modules/webpack/bin/webpack.js",
  #     "--mode",
  #     "production",
  #     "--watch-stdin",
  #     cd: "assets"
  #   ]
  # ],
  # live_reload: [
  #   patterns: [
  #     ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
  #     ~r"lib/phoenix/live_dashboard/(live|views)/.*(ex)$",
  #     ~r"lib/phoenix/live_dashboard/templates/.*(ex)$"
  #   ]
  # ],
  server: true
)

defmodule DemoWeb.PageController do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, :index) do
    content(conn, """
    <h2>Phoenix LiveDashboard Dev</h2>
    <a href="/dashboard" target="_blank">Open Dashboard</a>
    """)
  end

  defp content(conn, content) do
    conn
    |> put_resp_header("content-type", "text/html")
    |> send_resp(200, "<!doctype html><html><body>#{content}</body></html>")
  end
end

defmodule DemoWeb.Router do
  use Phoenix.Router
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug(:fetch_session)
  end

  scope "/" do
    pipe_through(:browser)
    get("/", DemoWeb.PageController, :index)

    live_dashboard("/dashboard",
      env_keys: ["USER", "ROOTDIR"],
      additional_pages: [
        {"psql_stats", {Phoenix.LiveDashboard.Pages.PSQLStatsPage, %{repo: DemoWeb.Repo}}}
      ]
    )
  end
end

defmodule DemoWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :phoenix_live_dashboard

  socket("/live", Phoenix.LiveView.Socket)
  # socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)

  # plug(Phoenix.LiveReloader)
  # plug(Phoenix.CodeReloader)

  plug(Plug.Session,
    store: :cookie,
    key: "_live_view_key",
    signing_salt: "/VEDsdfsffMnp5"
  )

  plug(Plug.RequestId)
  plug(DemoWeb.Router)
end

# Configures the endpoint
Application.put_env(:phoenix_live_dashboard, DemoWeb.Repo,
  database: "TO_BE_UPDATED",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"
)

defmodule DemoWeb.Repo do
  use Ecto.Repo, otp_app: :phoenix_live_dashboard, adapter: Ecto.Adapters.Postgres
end

Application.put_env(:phoenix, :serve_endpoints, true)
Application.put_env(:phoenix, :json_library, Jason)

{:ok, _} = Application.ensure_all_started(:postgrex)
{:ok, _} = Application.ensure_all_started(:ecto_sql)
{:ok, _} = Application.ensure_all_started(:ecto)
{:ok, _} = Application.ensure_all_started(:phoenix)
{:ok, _} = Application.ensure_all_started(:phoenix_live_view)
{:ok, _} = Application.ensure_all_started(:phoenix_live_dashboard)

Task.start(fn ->
  children = [
    {Phoenix.PubSub, [name: Demo.PubSub, adapter: Phoenix.PubSub.PG2]},
    # DemoWeb.Repo,
    DemoWeb.Endpoint
  ]

  {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)
  Process.sleep(:infinity)
end)
