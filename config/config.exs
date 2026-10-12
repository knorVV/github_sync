import Config

config :github_sync, GithubSync.Repo,
  database: System.get_env("DB_NAME", "github_sync_dev"),
  username: System.get_env("DB_USER", "postgres"),
  password: System.get_env("DB_PASS", "postgres"),
  hostname: System.get_env("DB_HOST", "localhost"),
  pool_size: 10

config :github_sync,
  ecto_repos: [GithubSync.Repo],
  github_sync_interval_minutes: String.to_integer(System.get_env("SYNC_INTERVAL_MINUTES", "5")),
  github_token: System.get_env("GITHUB_TOKEN")

config :logger, level: :info

config :github_sync, cli_base_url: "http://localhost:4000"

import_config "#{config_env()}.exs"
