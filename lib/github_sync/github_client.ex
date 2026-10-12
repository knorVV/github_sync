defmodule GithubSync.GithubClient do
  @moduledoc """
  Клиент GitHub Search API.
  Официального /trending endpoint нет, поэтому используем search
  с сортировкой по звёздам и фильтром по дате создания.
  """

  @search_url "https://api.github.com/search/repositories"

  @doc """
  Получить трендовые репозитории.
  limit — максимальное количество (не больше 100 за один запрос).
  """
  def fetch_trending(limit \\ 30) do
    days = 7
    week_ago = Date.utc_today() |> Date.add(-days) |> Date.to_iso8601()
    query = "created:>#{week_ago}"

    params = [
      q: query,
      sort: "stars",
      order: "desc",
      per_page: min(limit, 100)
    ]

    case Req.get(@search_url, params: params, headers: build_headers()) do
      {:ok, %{status: 200, body: %{"items" => items}}} ->
        {:ok, Enum.map(items, &normalize/1)}

      {:ok, %{status: 403, headers: resp_headers}} ->
        {:error, {:rate_limited, parse_rate_limit(resp_headers)}}

      {:ok, %{status: 422, body: body}} ->
        {:error, {:unprocessable, body}}

      {:ok, %{status: status, body: body}} ->
        {:error, {:github_error, status, body}}

      {:error, reason} ->
        {:error, {:http_error, reason}}
    end
  end

  defp build_headers do
    base = [
      {"accept", "application/vnd.github+json"},
      {"user-agent", "github-sync-service"}
    ]

    case Application.get_env(:github_sync, :github_token) do
      nil -> base
      "" -> base
      token -> [{"authorization", "Bearer #{token}"} | base]
    end
  end

  defp normalize(item) do
    %{
      github_id: item["id"],
      name: item["name"],
      full_name: item["full_name"],
      description: item["description"],
      html_url: item["html_url"],
      stars: item["stargazers_count"],
      language: item["language"],
      owner_login: get_in(item, ["owner", "login"]),
      github_created_at: parse_dt(item["created_at"]),
      github_updated_at: parse_dt(item["updated_at"])
    }
  end

  defp parse_dt(nil), do: nil

  defp parse_dt(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} -> DateTime.truncate(dt, :second)
      _ -> nil
    end
  end

  defp parse_rate_limit(headers) do
    %{
      remaining: header(headers, "x-ratelimit-remaining"),
      reset: header(headers, "x-ratelimit-reset")
    }
  end

  defp header(headers, key) do
    headers
    |> Enum.find(fn {k, _} -> String.downcase(k) == key end)
    |> case do
      {_, v} -> v
      nil -> nil
    end
  end
end
