defmodule PeriodicCollect do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    File.write("/home/skystar/yes", "yo")
    metric_collection()
    {:ok, state}
  end

  def handle_info(:collect_metric, state) do
    # do something...
    Task.start_link(&task_collect_metric/0)
    metric_collection()
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp task_collect_metric() do
    IO.puts "working!"
  end

  defp metric_collection() do
    # Periodic task of 1000ms
    Process.send_after(self(), :collect_metric, 1000)
  end

end
