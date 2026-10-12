defmodule GithubSync.CLI do
  @moduledoc """
  CLI-клиент для GitHub Sync Service.

  Сборка: mix escript.build
  Запуск: ./github_sync_cli <command>
  """
  @base_url Application.compile_env(:github_sync, :cli_base_url, "http://localhost:4000")

  def main(args) do
    args
    |> parse_args()
    |> execute()
  end

  defp parse_args(["get", name]), do: {:get, name}
  defp parse_args(["list"]), do: :list
  defp parse_args(["sync"]), do: :sync
  defp parse_args(_), do: :help

  defp execute({:get, name}) do
    case Req.get("#{@base_url}/api/repos/#{URI.encode(name)}") do
      {:ok, %{status: 200, body: repo}} -> print_repo(repo)
      {:ok, %{status: 404}} -> IO.puts("Repository not found: #{name}")
      {:ok, %{status: status}} -> IO.puts("Error: HTTP #{status}")
      {:error, reason} -> IO.puts("Connection error: #{inspect(reason)}")
    end
  end

  defp execute(:list) do
    case Req.get("#{@base_url}/api/repos") do
      {:ok, %{status: 200, body: %{"data" => repos, "count" => count}}} ->
        IO.puts("Total repositories: #{count}\n")

        repos
        |> Enum.take(20)
        |> Enum.each(fn r ->
          IO.puts("  #{r["full_name"]} — #{r["stars"]} ⭐ (#{r["language"] || "n/a"})")
        end)

        if count > 20, do: IO.puts("\n... and #{count - 20} more")

      {:ok, %{status: status}} ->
        IO.puts("Error: HTTP #{status}")

      {:error, reason} ->
        IO.puts("Connection error: #{inspect(reason)}")
    end
  end

  defp execute(:sync) do
    case Req.post("#{@base_url}/api/sync") do
      {:ok, %{status: 202}} -> IO.puts("Sync started. Timer reset.")
      {:ok, %{status: status}} -> IO.puts("Error: HTTP #{status}")
      {:error, reason} -> IO.puts("Connection error: #{inspect(reason)}")
    end
  end

  defp execute(:help) do
    IO.puts("""
    GitHub Sync CLI

    Usage:
      github_sync_cli list          List all repositories (top 20)
      github_sync_cli get <name>    Get repo by name, full_name or GitHub ID
      github_sync_cli sync          Force sync with GitHub (resets timer)
    """)
  end

  defp print_repo(r) do
    IO.puts("""
    #{r["full_name"]}
    ----------------------------------------
    Description: #{r["description"] || "n/a"}
    Stars:       #{r["stars"]}
    Language:    #{r["language"] || "n/a"}
    Owner:       #{r["owner_login"] || "n/a"}
    URL:         #{r["html_url"]}
    """)
  end
end
