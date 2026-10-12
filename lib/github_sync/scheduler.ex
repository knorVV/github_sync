defmodule GithubSync.Scheduler do
  @moduledoc """
  Планировщик синхронизации без cron.

  Использует Process.send_after для самопланирования.
  Force sync отменяет текущий таймер и запускает синхронизацию немедленно,
  после чего ставит новый таймер на полный интервал.
  """
  use GenServer
  require Logger

  @default_interval_ms 5 * 60 * 1000

  # --- Public API ---

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Принудительная синхронизация.
  Сбрасывает внутренний таймер и запускает синхронизацию немедленно.
  """
  def force_sync do
    GenServer.cast(__MODULE__, :force_sync)
  end

  @doc "Текущий интервал в миллисекундах."
  def interval do
    GenServer.call(__MODULE__, :interval)
  end

  # --- GenServer callbacks ---

  @impl true
  def init(opts) do
    interval = Keyword.get(opts, :interval, @default_interval_ms)
    state = %{interval: interval, timer_ref: nil}
    {:ok, state, {:continue, :schedule_first}}
  end

  @impl true
  def handle_continue(:schedule_first, state) do
    send(self(), :sync)
    {:noreply, state}
  end

  @impl true
  def handle_info(:sync, state) do
    run_sync()
    new_ref = schedule_next(state.interval)
    {:noreply, %{state | timer_ref: new_ref}}
  end

  @impl true
  def handle_cast(:force_sync, state) do
    Logger.info("Force sync requested — resetting timer")
    cancel_timer(state.timer_ref)
    send(self(), :sync)
    {:noreply, %{state | timer_ref: nil}}
  end

  @impl true
  def handle_call(:interval, _from, state) do
    {:reply, state.interval, state}
  end

  defp run_sync do
    Logger.info("Starting GitHub sync...")

    case GithubSync.GithubClient.fetch_trending(30) do
      {:ok, repos} ->
        dbg(repos)
        GithubSync.RepoStores.upsert_all(repos)
        Logger.info("Synced #{length(repos)} repositories")

      {:error, reason} ->
        Logger.error("Sync failed: #{inspect(reason)}")
    end
  end

  defp schedule_next(interval) do
    Process.send_after(self(), :sync, interval)
  end

  defp cancel_timer(nil), do: :ok
  defp cancel_timer(ref), do: Process.cancel_timer(ref)
end
