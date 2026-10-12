import Config

config :github_sync, GithubSync.Repo,
  database: "github_sync_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warning
