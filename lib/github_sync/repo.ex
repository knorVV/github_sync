defmodule GithubSync.Repo do
  use Ecto.Repo,
    otp_app: :github_sync,
    adapter: Ecto.Adapters.Postgres
end
