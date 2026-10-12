defmodule GithubSync.Repo.Migrations.CreateRepos do
  use Ecto.Migration

  def change do
    create table(:repos) do
      add :github_id, :bigint, null: false
      add :name, :string, null: false
      add :full_name, :string
      add :description, :text
      add :html_url, :string
      add :stars, :integer, default: 0
      add :language, :string
      add :owner_login, :string
      add :github_created_at, :utc_datetime
      add :github_updated_at, :utc_datetime

      timestamps()
    end

    create unique_index(:repos, [:github_id])
    create index(:repos, [:stars])
    create index(:repos, [:name])
    create index(:repos, [:full_name])
  end
end
