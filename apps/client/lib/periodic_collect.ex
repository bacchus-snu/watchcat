defmodule PeriodicCollect do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    # Setup ETS table
    :ets.new(:metric, [:named_table])

    metric_collection()
    {:ok, state}
  end

  def handle_info(:collect_metric, state) do
    # do something...
    # TODO: make below ASYNC
    task_collect_metric()
    metric_collection()
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp task_collect_metric() do
    metrics = [
      {:cpu_metric, Metric.fetch_cpu_usage},
      {:memory_metric, Metric.fetch_memory_usage},
      {:disk_metric, Metric.fetch_disk_usage},
      {:network_metric, Metric.fetch_network_usage},
    ]

    [cpu, memory, disk, network] = metrics

    # cpu |> inspect |> IO.puts
    :ets.insert(:metric, {:cpu, calculate_cpu_usage(cpu)})
    # memory |> inspect |> IO.puts
    # disk |> inspect |> IO.puts
    # network |> inspect |> IO.puts

    :ets.insert(:metric, metrics)
  end

  defp calculate_cpu_usage({:cpu_metric, curr}) do
    case :ets.lookup(:metric, :cpu_metric) |> List.first do
      nil ->
        :not_available
      {:cpu_metric, prev} ->
        for {prev_core, curr_core} <- Enum.zip(prev, curr),
          name = prev_core["name"],
          idle = curr_core["idle"] - prev_core["idle"],
          total = curr_core["total"] - prev_core["total"],
          usage_percent = ((total - idle) / total) * 100 do
            %{"name" => name, "usage" => usage_percent}
          end
    end
  end

  defp calculate_memory_usage({:memory_metric, metric}) do

  end

  defp calculate_disk_usage(metric) do

  end

  defp metric_collection() do
    # Periodic task of 1000ms
    Process.send_after(self(), :collect_metric, 1000)
  end

end
