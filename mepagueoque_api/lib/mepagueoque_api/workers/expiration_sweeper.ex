defmodule MepagueoqueApi.Workers.ExpirationSweeper do
  @moduledoc """
  Periodic task that deletes expired `payment_links` rows.

  Wraps a stateless `sweep/0` function in a GenServer that re-schedules itself
  every 6 hours via `Process.send_after/3`. The GenServer itself holds no state
  beyond the timer; `sweep/0` is safe to call standalone (tests rely on this).
  """

  use GenServer
  require Logger
  import Ecto.Query
  alias MepagueoqueApi.{Repo, Schemas.PaymentLink}

  @interval :timer.hours(6)

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    schedule()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:sweep, state) do
    sweep()
    schedule()
    {:noreply, state}
  end

  @doc """
  Deletes every `payment_links` row whose `expires_at` is strictly in the past.

  Returns the count of rows deleted. Safe to call from anywhere — does not
  depend on the GenServer process being alive.
  """
  @spec sweep() :: integer()
  def sweep do
    now = DateTime.utc_now()
    {count, _} = Repo.delete_all(from(p in PaymentLink, where: p.expires_at < ^now))
    if count > 0, do: Logger.info("ExpirationSweeper: deleted #{count} expired payment_links")
    count
  end

  defp schedule, do: Process.send_after(self(), :sweep, @interval)
end
