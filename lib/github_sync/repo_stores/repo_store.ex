defmodule GithubSync.RepoStore do
  @moduledoc """
  Ecto-схема и операции с таблицей repos.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "repos" do
    field(:github_id, :integer)
    field(:name, :string)
    field(:full_name, :string)
    field(:description, :string)
    field(:html_url, :string)
    field(:stars, :integer, default: 0)
    field(:language, :string)
    field(:owner_login, :string)
    field(:github_created_at, :utc_datetime)
    field(:github_updated_at, :utc_datetime)

    timestamps()
  end

  def changeset(repo, attrs) do
    repo
    |> cast(attrs, [
      :github_id,
      :name,
      :full_name,
      :description,
      :html_url,
      :stars,
      :language,
      :owner_login,
      :github_created_at,
      :github_updated_at
    ])
    |> validate_required([:github_id, :name])
    |> unique_constraint(:github_id)
  end
end
