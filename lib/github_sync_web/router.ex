defmodule GithubSyncWeb.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/api/repos" do
    GithubSyncWeb.RepoController.list(conn)
  end

  get "/api/repos/:id" do
    GithubSyncWeb.RepoController.get_by_id(conn, id)
  end

  post "/api/sync" do
    GithubSyncWeb.RepoController.sync(conn)
  end

  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{error: "not_found"}))
  end
end
