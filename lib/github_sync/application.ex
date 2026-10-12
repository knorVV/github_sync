defmodule GithubSync.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    interval_minutes = Application.get_env(:github_sync, :github_sync_interval_minutes, 5)
    interval_ms = interval_minutes * 60 * 1000

    children = [
      GithubSync.Repo,
      {GithubSync.Scheduler, interval: interval_ms},
      {Plug.Cowboy, scheme: :http, plug: GithubSyncWeb.Router, options: [port: 4000]}
    ]

    opts = [strategy: :one_for_one, name: GithubSync.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
