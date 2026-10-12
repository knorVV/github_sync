defmodule GithubSync.RepoStores do
  @moduledoc false

  import Ecto.Query

  alias GithubSync.Repo
  alias GithubSync.RepoStore

  @doc """
  Идемпотентное сохранение списка репозиториев.
  UPSERT по github_id: при конфликте обновляем звёзды и метаданные.
  """
  def upsert_all([]), do: {0, nil}

  def upsert_all(repos_attrs) when is_list(repos_attrs) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    entries =
      Enum.map(repos_attrs, fn attrs ->
        attrs
        |> Map.put(:inserted_at, now)
        |> Map.put(:updated_at, now)
      end)

    Repo.insert_all(
      RepoStore,
      entries,
      on_conflict:
        {:replace,
         [
           :stars,
           :description,
           :full_name,
           :html_url,
           :language,
           :owner_login,
           :github_updated_at,
           :updated_at
         ]},
      conflict_target: [:github_id]
    )
  end

  @doc "Список всех репозиториев, отсортированных по звёздам."
  def list_all do
    Repo.all(from(r in RepoStore, order_by: [desc: r.stars]))
  end

  @doc "Поиск по GitHub ID или локальному ID."
  def get_by_github_id(id) when is_integer(id) do
    Repo.one(from(r in RepoStore, where: r.github_id == ^id))
  end

  @doc "Поиск по имени или full_name."
  def get_by_name(name) when is_binary(name) do
    Repo.one(
      from(r in RepoStore,
        where: r.name == ^name or r.full_name == ^name,
        limit: 1
      )
    )
  end

  def count do
    Repo.aggregate(RepoStore, :count, :id)
  end
end
