defmodule GithubSyncWeb.RepoController do
  @moduledoc false
  import Plug.Conn

  alias GithubSync.RepoStores

  def get_by_id(conn, id) do
    repo =
      case Integer.parse(id) do
        {int_id, ""} ->
          RepoStores.get_by_github_id(int_id) || safe_get_by_name(id)

        _ ->
          safe_get_by_name(id)
      end

    case repo do
      nil -> send_json(conn, 404, %{error: "not_found", id: id})
      repo -> send_json(conn, 200, serialize(repo))
    end
  end

  def list(conn) do
    repos = RepoStores.list_all()
    send_json(conn, 200, %{count: length(repos), data: Enum.map(repos, &serialize/1)})
  end

  def sync(conn) do
    GithubSync.Scheduler.force_sync()
    send_json(conn, 202, %{status: "sync_started"})
  end

  # --- Private ---

  defp safe_get_by_name(name) do
    RepoStores.get_by_name(name)
  rescue
    _ -> nil
  end

  defp serialize(repo) do
    %{
      id: repo.id,
      github_id: repo.github_id,
      name: repo.name,
      full_name: repo.full_name,
      description: repo.description,
      html_url: repo.html_url,
      stars: repo.stars,
      language: repo.language,
      owner_login: repo.owner_login,
      github_created_at: repo.github_created_at,
      github_updated_at: repo.github_updated_at
    }
  end

  defp send_json(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> put_resp_header("access-control-allow-origin", "*")
    |> send_resp(status, Jason.encode!(body))
  end
end
